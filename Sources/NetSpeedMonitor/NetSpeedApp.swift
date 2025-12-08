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
            VStack(alignment: .trailing, spacing: 0) {
                HStack(spacing: 2) {
                    Text(stats.downloadSpeed)
                    Image(systemName: "arrow.down")
                        .imageScale(.small)
                }
                HStack(spacing: 2) {
                    Text(stats.uploadSpeed)
                    Image(systemName: "arrow.up")
                        .imageScale(.small)
                }
            }
            .monospacedDigit()
            .font(.system(size: 9))
            .frame(width: 60, alignment: .trailing)
        }
    }
}
