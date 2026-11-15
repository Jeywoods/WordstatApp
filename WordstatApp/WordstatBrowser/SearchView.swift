import SwiftUI

struct SearchView: View {
    @StateObject private var vm = SearchViewModel()
    @EnvironmentObject var network: NetworkMonitor

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Wordstat")
                .searchable(text: $vm.query, prompt: "Ключевая фраза")
                .onSubmit(of: .search) { Task { await vm.search() } }
                .navigationDestination(for: PhraseCount.self) { DetailView(item: $0) }
                .refreshable { await vm.search() }
        }
        .offlineBanner()
        .task { await vm.search() }
        .onChange(of: network.isConnected) { connected in
            if connected, case .failed = vm.state { Task { await vm.search() } }
        }
    }

    @ViewBuilder private var content: some View {
        switch vm.state {
        case .idle:
            ContentUnavailableLabel(title: "Введите фразу", systemImage: "magnifyingglass")
        case .loading where vm.top.isEmpty:
            ProgressView("Загрузка…").frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let msg):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle").font(.largeTitle)
                Text(msg).multilineTextAlignment(.center)
                Button("Повторить") { Task { await vm.search() } }.buttonStyle(.borderedProminent)
            }.padding().frame(maxWidth: .infinity, maxHeight: .infinity)
        default:
            List {
                Section("Популярные запросы (30 дней)") {
                    ForEach(vm.top) { row($0) }
                }
                if !vm.associations.isEmpty {
                    Section("Похожие запросы") {
                        ForEach(vm.associations) { row($0) }
                    }
                }
            }
            .animation(.default, value: vm.top)
        }
    }

    private func row(_ item: PhraseCount) -> some View {
        NavigationLink(value: item) {
            HStack {
                Text(item.phrase)
                Spacer()
                Text(item.count.formatted()).foregroundStyle(.secondary).monospacedDigit()
            }
        }
    }
}

struct ContentUnavailableLabel: View {
    let title: String, systemImage: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage).font(.largeTitle)
            Text(title)
        }.foregroundStyle(.secondary).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
