import Foundation
import SystemConfiguration

class NetworkStats: ObservableObject {
    @Published var uploadSpeed: String = "0 KB/s"
    @Published var downloadSpeed: String = "0 KB/s"
    
    var onUpdate: ((String, String) -> Void)?

    private var timer: Timer?
    private var previousBytesIn: UInt64 = 0
    private var previousBytesOut: UInt64 = 0
    private var isFirstReading = true

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSpeed()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func updateSpeed() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0 else { return }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        var totalBytesIn: UInt64 = 0
        var totalBytesOut: UInt64 = 0

        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            let interface = ptr?.pointee
            let addrFamily = interface?.ifa_addr.pointee.sa_family

            // AF_LINK is 18 on macOS, used to get link layer data (bytes)
            if addrFamily == UInt8(AF_LINK) {
                let name = String(cString: (interface?.ifa_name)!)

                // Filter out loopback, monitor all others (en, utun, etc)
                if !name.hasPrefix("lo") {
                    let data = interface?.ifa_data.assumingMemoryBound(to: if_data.self)
                    totalBytesIn += UInt64(data?.pointee.ifi_ibytes ?? 0)
                    totalBytesOut += UInt64(data?.pointee.ifi_obytes ?? 0)
                }
            }
        }

        if isFirstReading {
            previousBytesIn = totalBytesIn
            previousBytesOut = totalBytesOut
            isFirstReading = false
            return
        }

        let bytesInDelta = totalBytesIn >= previousBytesIn ? totalBytesIn - previousBytesIn : 0
        let bytesOutDelta = totalBytesOut >= previousBytesOut ? totalBytesOut - previousBytesOut : 0
        
        DispatchQueue.main.async {
            self.downloadSpeed = self.formatBytes(bytesInDelta) + "/s"
            self.uploadSpeed = self.formatBytes(bytesOutDelta) + "/s"
            self.onUpdate?(self.downloadSpeed, self.uploadSpeed)
        }

        previousBytesIn = totalBytesIn
        previousBytesOut = totalBytesOut
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let b = Double(bytes)
        if b < 1024 {
            return String(format: "%6.0f B ", b)
        } else if b < 1024 * 1024 {
            return String(format: "%6.1f KB", b / 1024)
        } else if b < 1024 * 1024 * 1024 {
            return String(format: "%6.1f MB", b / (1024 * 1024))
        } else {
            return String(format: "%6.2f GB", b / (1024 * 1024 * 1024))
        }
    }
}
