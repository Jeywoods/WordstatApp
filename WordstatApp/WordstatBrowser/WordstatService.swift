import Foundation

enum APIError: LocalizedError {
    case noToken, offline, unauthorized, quota, server(Int, String), decoding

    var errorDescription: String? {
        switch self {
        case .noToken: return "Токен не указан. Откройте файл Secrets.swift и вставьте свой OAuth-токен."
        case .offline: return "Нет подключения к сети. Проверьте интернет и повторите."
        case .unauthorized: return "Токен неверный или просрочен (401/403). Получите новый токен."
        case .quota: return "Превышен лимит запросов (429). Подождите и повторите."
        case .server(let code, let msg): return "Ошибка сервера \(code). \(msg)"
        case .decoding: return "Не удалось разобрать ответ сервера."
        }
    }
}

struct WordstatService {
    private let base = URL(string: "https://api.wordstat.yandex.net")!
    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 20
        return URLSession(configuration: c)
    }()

    func topRequests(phrase: String) async throws -> TopRequestsResponse {
        try await post("/v1/topRequests", TopRequestsBody(phrase: phrase))
    }

    /// Динамика по месяцам за последние 12 полных месяцев.
    func dynamics(phrase: String) async throws -> DynamicsResponse {
        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let startOfThisMonth = cal.date(from: cal.dateComponents([.year, .month], from: now))!
        let from = cal.date(byAdding: .month, value: -12, to: startOfThisMonth)!   // 1-е число месяца (требование API)
        let to = cal.date(byAdding: .day, value: -1, to: startOfThisMonth)!         // конец прошлого месяца
        return try await post("/v1/dynamics",
                              DynamicsBody(phrase: phrase, period: "monthly",
                                           fromDate: Self.fmt.string(from: from),
                                           toDate: Self.fmt.string(from: to)))
    }

    func regions(phrase: String) async throws -> RegionsResponse {
        try await post("/v1/regions", RegionsBody(phrase: phrase, regionType: "cities"))
    }

    static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func post<B: Encodable, R: Decodable>(_ path: String, _ body: B) async throws -> R {
        let token = Secrets.oauthToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty, token != "ВСТАВЬТЕ_ТОКЕН_СЮДА" else { throw APIError.noToken }
        var req = URLRequest(url: base.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try JSONEncoder().encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch let e as URLError where [.notConnectedToInternet, .networkConnectionLost, .dataNotAllowed].contains(e.code) {
            throw APIError.offline
        }
        guard let http = response as? HTTPURLResponse else { throw APIError.decoding }
        switch http.statusCode {
        case 200..<300: break
        case 401, 403: throw APIError.unauthorized
        case 429: throw APIError.quota
        default: throw APIError.server(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        do { return try JSONDecoder().decode(R.self, from: data) }
        catch { throw APIError.decoding }
    }
}
