import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    enum State { case idle, loading, loaded, failed(String) }

    @Published var query = "яндекс"
    @Published var top: [PhraseCount] = []
    @Published var associations: [PhraseCount] = []
    @Published var state: State = .idle

    private let service = WordstatService()

    func search() async {
        let phrase = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !phrase.isEmpty else { return }
        state = .loading
        do {
            let r = try await service.topRequests(phrase: phrase)
            top = r.topRequests
            associations = r.associations ?? []
            state = .loaded
        } catch is CancellationError {
            // pull-to-refresh отменён — ничего не делаем
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
