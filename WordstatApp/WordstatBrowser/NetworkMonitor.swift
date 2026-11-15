import Network
import SwiftUI

@MainActor
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let ok = path.status == .satisfied
            Task { @MainActor in self?.isConnected = ok }
        }
        monitor.start(queue: queue)
    }
    deinit { monitor.cancel() }
}

struct OfflineBanner: ViewModifier {
    @EnvironmentObject var network: NetworkMonitor
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            if !network.isConnected {
                Label("Нет подключения к сети", systemImage: "wifi.slash")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut, value: network.isConnected)
    }
}
extension View { func offlineBanner() -> some View { modifier(OfflineBanner()) } }
