import SwiftUI
import Charts

@MainActor
final class DetailViewModel: ObservableObject {
    @Published var dynamics: [DynamicsPoint] = []
    @Published var regions: [RegionStat] = []
    @Published var loading = true
    @Published var error: String?
    private let service = WordstatService()

    func load(_ phrase: String) async {
        loading = true; error = nil
        async let d = service.dynamics(phrase: phrase)
        async let r = service.regions(phrase: phrase)
        do {
            dynamics = try await d.dynamics
            regions = Array(try await r.regions.sorted { $0.count > $1.count }.prefix(15))
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }
}

struct DetailView: View {
    let item: PhraseCount
    @StateObject private var vm = DetailViewModel()

    var body: some View {
        List {
            Section {
                LabeledContent("Запросов за 30 дней", value: item.count.formatted())
            }
            if vm.loading {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if let e = vm.error {
                Section {
                    Text(e).foregroundStyle(.red)
                    Button("Повторить") { Task { await vm.load(item.phrase) } }
                }
            } else {
                Section("Динамика по месяцам") {
                    Chart(vm.dynamics) { p in
                        BarMark(x: .value("Месяц", Self.parse(p.date), unit: .month),
                                y: .value("Запросов", p.count))
                    }
                    .frame(height: 200)
                    ForEach(vm.dynamics.reversed()) { p in
                        HStack {
                            Text(p.date.prefix(7))
                            Spacer()
                            Text(p.count.formatted()).monospacedDigit()
                            Text(String(format: "%.3f%%", p.share * 100))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Топ городов") {
                    ForEach(vm.regions) { r in
                        HStack {
                            Text("Регион ID \(r.regionId)")
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(r.count.formatted()).monospacedDigit()
                                if let a = r.affinityIndex {
                                    Text("индекс интереса \(Int(a))%").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(item.phrase)
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(item.phrase) }
    }

    private static func parse(_ s: String) -> Date { WordstatService.fmt.date(from: s) ?? .now }
}
