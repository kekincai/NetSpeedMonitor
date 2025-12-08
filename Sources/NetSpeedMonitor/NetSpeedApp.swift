import SwiftUI

@main
struct NetSpeedApp: App {
    @StateObject private var stats = NetworkStats()

    var body: some Scene {
        MenuBarExtra {
            Text("Network Speed Monitor")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.down")
                Text(stats.downloadSpeed)
                Image(systemName: "arrow.up")
                Text(stats.uploadSpeed)
            }
            .monospacedDigit()
        }
    }
}
