import Foundation

/// Число в JSON может прийти как Int или как строка — читаем оба варианта.
private func decodeCount(_ c: KeyedDecodingContainer<PhraseCount.CodingKeys>) throws -> Int {
    if let v = try? c.decode(Int.self, forKey: .count) { return v }
    let s = try c.decode(String.self, forKey: .count)
    guard let v = Int(s) else { throw DecodingError.dataCorruptedError(forKey: .count, in: c, debugDescription: "count") }
    return v
}

struct PhraseCount: Decodable, Identifiable, Hashable {
    let phrase: String
    let count: Int
    var id: String { phrase }

    enum CodingKeys: String, CodingKey { case phrase, count }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        phrase = try c.decode(String.self, forKey: .phrase)
        count = try decodeCount(c)
    }
}

struct TopRequestsResponse: Decodable {
    let topRequests: [PhraseCount]
    let associations: [PhraseCount]?
}

struct DynamicsPoint: Decodable, Identifiable {
    let date: String
    let count: Int
    let share: Double
    var id: String { date }
}
struct DynamicsResponse: Decodable { let dynamics: [DynamicsPoint] }

struct RegionStat: Decodable, Identifiable {
    let regionId: Int
    let count: Int
    let share: Double
    let affinityIndex: Double?
    var id: Int { regionId }
}
struct RegionsResponse: Decodable { let regions: [RegionStat] }

// MARK: - Request bodies
struct TopRequestsBody: Encodable { let phrase: String }
struct DynamicsBody: Encodable {
    let phrase: String
    let period: String
    let fromDate: String
    let toDate: String?
}
struct RegionsBody: Encodable {
    let phrase: String
    let regionType: String
}
