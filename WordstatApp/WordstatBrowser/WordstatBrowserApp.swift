import SwiftUI

@main
struct WordstatBrowserApp: App {
    @StateObject private var network = NetworkMonitor()
    var body: some Scene {
        WindowGroup {
            SearchView()
                .environmentObject(network)
        }
    }
}
