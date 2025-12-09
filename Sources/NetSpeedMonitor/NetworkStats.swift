import Foundation
import SystemConfiguration

// 进程流量信息结构
struct ProcessTraffic: Identifiable {
    let id = UUID()
    let name: String
    let download: UInt64
    let upload: UInt64
}

// NetworkStats 类负责监控和计算网络速度
// ObservableObject 协议允许 SwiftUI 视图观察此对象的变化
class NetworkStats: ObservableObject {
    // @Published 属性包装器会在值改变时自动通知观察者
    @Published var uploadSpeed: String = "0 KB/s"      // 上传速度
    @Published var downloadSpeed: String = "0 KB/s"    // 下载速度
    
    // 详细信息属性
    @Published var speedHistory: [Double] = Array(repeating: 0, count: 20)  // 最近20秒的速度历史
    @Published var wifiSSID: String? = nil                                    // WiFi 名称
    @Published var localIP: String = "获取中..."                              // 本地 IP
    @Published var publicIP: String = "获取中..."                             // 外网 IP
    @Published var pingTime: String = "-- ms"                                 // Ping 延迟
    @Published var todayUsage: String = "0 B"                                 // 今日流量
    @Published var monthUsage: String = "0 B"                                 // 本月流量
    @Published var topProcesses: [ProcessTraffic] = []                        // Top 流量进程
    @Published var networkHealth: String = "检测中"                           // 网络健康状态
    @Published var packetLoss: String = "0%"                                  // 丢包率
    @Published var wifiSignal: String? = nil                                  // WiFi 信号强度
    
    // 回调函数，当速度更新时调用
    // 参数：(下载速度字符串, 上传速度字符串)
    var onUpdate: ((String, String) -> Void)?

    // 定时器，每秒触发一次速度更新
    private var timer: Timer?
    // 上一次读取的接收字节数（下载）
    private var previousBytesIn: UInt64 = 0
    // 上一次读取的发送字节数（上传）
    private var previousBytesOut: UInt64 = 0
    // 标记是否是第一次读取数据
    private var isFirstReading = true

    // 累计流量统计
    private var totalBytesInToday: UInt64 = 0
    private var totalBytesOutToday: UInt64 = 0
    private var totalBytesInMonth: UInt64 = 0
    private var totalBytesOutMonth: UInt64 = 0
    
    // 初始化方法，创建对象时自动调用
    init() {
        // 初始化一些模拟数据
        topProcesses = [
            ProcessTraffic(name: "Safari", download: 0, upload: 0),
            ProcessTraffic(name: "Chrome", download: 0, upload: 0),
            ProcessTraffic(name: "Xcode", download: 0, upload: 0)
        ]
        
        startMonitoring()
        fetchNetworkInfo()
    }

    // 开始监控网络速度
    func startMonitoring() {
        // 创建一个定时器，每 1.0 秒触发一次
        // withTimeInterval: 时间间隔（秒）
        // repeats: true 表示重复执行
        // [weak self] 避免循环引用
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSpeed()
        }
    }

    // 停止监控网络速度
    func stopMonitoring() {
        timer?.invalidate()  // 使定时器失效
        timer = nil          // 释放定时器对象
    }

    // 更新网络速度的核心方法
    private func updateSpeed() {
        // ifaddr 是一个指向网络接口地址链表的指针
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        // getifaddrs 获取所有网络接口的信息
        // 返回 0 表示成功，否则失败
        guard getifaddrs(&ifaddr) == 0 else { return }
        // defer 确保函数退出时释放内存
        defer { freeifaddrs(ifaddr) }

        // ptr 用于遍历链表
        var ptr = ifaddr
        // 累计所有接口的接收字节数
        var totalBytesIn: UInt64 = 0
        // 累计所有接口的发送字节数
        var totalBytesOut: UInt64 = 0

        // 遍历所有网络接口
        while ptr != nil {
            // defer 在每次循环结束时移动到下一个接口
            defer { ptr = ptr?.pointee.ifa_next }

            let interface = ptr?.pointee
            // 获取地址族类型
            let addrFamily = interface?.ifa_addr.pointee.sa_family

            // AF_LINK 在 macOS 上值为 18，表示链路层数据
            // 链路层包含实际的字节传输统计信息
            if addrFamily == UInt8(AF_LINK) {
                // 获取接口名称（如 en0, en1, utun0 等）
                let name = String(cString: (interface?.ifa_name)!)

                // 过滤掉回环接口（lo0），只统计真实的网络接口
                // hasPrefix 检查字符串是否以指定前缀开头
                if !name.hasPrefix("lo") {
                    // ifa_data 包含接口的统计数据
                    // assumingMemoryBound 将指针转换为 if_data 类型
                    let data = interface?.ifa_data.assumingMemoryBound(to: if_data.self)
                    // ifi_ibytes: 接收的字节数（input bytes，下载）
                    totalBytesIn += UInt64(data?.pointee.ifi_ibytes ?? 0)
                    // ifi_obytes: 发送的字节数（output bytes，上传）
                    totalBytesOut += UInt64(data?.pointee.ifi_obytes ?? 0)
                }
            }
        }

        // 第一次读取时，只记录初始值，不计算速度
        // 因为没有上一次的数据来计算差值
        if isFirstReading {
            previousBytesIn = totalBytesIn
            previousBytesOut = totalBytesOut
            isFirstReading = false
            return
        }

        // 计算这一秒内的字节变化量
        // 使用三元运算符确保不会出现负数（防止计数器溢出）
        let bytesInDelta = totalBytesIn >= previousBytesIn ? totalBytesIn - previousBytesIn : 0
        let bytesOutDelta = totalBytesOut >= previousBytesOut ? totalBytesOut - previousBytesOut : 0
        
        // 累计今日和本月流量
        totalBytesInToday += bytesInDelta
        totalBytesOutToday += bytesOutDelta
        totalBytesInMonth += bytesInDelta
        totalBytesOutMonth += bytesOutDelta
        
        // 更新速度历史记录（用于图表显示）
        let maxSpeed = 10.0 * 1024 * 1024  // 假设最大速度 10 MB/s
        let normalizedSpeed = min(Double(bytesInDelta) / maxSpeed, 1.0)
        speedHistory.removeFirst()
        speedHistory.append(normalizedSpeed)
        
        // 在主线程更新 UI
        // DispatchQueue.main.async 确保 UI 更新在主线程执行
        DispatchQueue.main.async {
            // 格式化字节数并添加 "/s" 后缀
            self.downloadSpeed = self.formatBytes(bytesInDelta) + "/s"
            self.uploadSpeed = self.formatBytes(bytesOutDelta) + "/s"
            
            // 更新流量统计
            self.todayUsage = self.formatBytes(self.totalBytesInToday + self.totalBytesOutToday)
            self.monthUsage = self.formatBytes(self.totalBytesInMonth + self.totalBytesOutMonth)
            
            // 调用回调函数通知外部
            self.onUpdate?(self.downloadSpeed, self.uploadSpeed)
        }

        // 保存当前值，供下次计算使用
        previousBytesIn = totalBytesIn
        previousBytesOut = totalBytesOut
    }
    
    // 获取网络信息（IP、WiFi 等）
    private func fetchNetworkInfo() {
        // 获取本地 IP
        getLocalIP()
        
        // 获取 WiFi 信息
        getWiFiInfo()
        
        // 获取外网 IP（异步）
        getPublicIP()
        
        // 测试 Ping
        testPing()
    }
    
    // 获取本地 IP 地址
    private func getLocalIP() {
        var address: String = "未连接"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interface = ptr?.pointee
                let addrFamily = interface?.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) {  // IPv4
                    let name = String(cString: (interface?.ifa_name)!)
                    if name == "en0" {  // WiFi 接口
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!),
                                  &hostname, socklen_t(hostname.count),
                                  nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                        break
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        DispatchQueue.main.async {
            self.localIP = address
        }
    }
    
    // 获取 WiFi 信息（SSID 和信号强度）
    private func getWiFiInfo() {
        // 注意：获取 WiFi SSID 需要特殊权限，这里提供简化版本
        // 实际应用需要添加 CoreWLAN 框架
        DispatchQueue.main.async {
            self.wifiSSID = "WiFi"  // 简化版本，实际需要使用 CWWiFiClient
            self.wifiSignal = "-50 dBm"
        }
    }
    
    // 获取外网 IP
    private func getPublicIP() {
        guard let url = URL(string: "https://api.ipify.org?format=text") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let ip = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.publicIP = ip
                }
            } else {
                DispatchQueue.main.async {
                    self.publicIP = "获取失败"
                }
            }
        }.resume()
    }
    
    // 测试 Ping 延迟
    private func testPing() {
        // 简化版本：使用 ping 命令
        DispatchQueue.global().async {
            let task = Process()
            task.launchPath = "/sbin/ping"
            task.arguments = ["-c", "1", "-t", "2", "8.8.8.8"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8) {
                    // 解析 ping 结果
                    if let range = output.range(of: "time=(\\d+\\.?\\d*)", options: .regularExpression) {
                        let timeStr = output[range].replacingOccurrences(of: "time=", with: "")
                        DispatchQueue.main.async {
                            self.pingTime = "\(timeStr) ms"
                            self.networkHealth = "良好"
                            self.packetLoss = "0%"
                        }
                        return
                    }
                }
            } catch {
                // Ping 失败
            }
            
            DispatchQueue.main.async {
                self.pingTime = "超时"
                self.networkHealth = "较差"
            }
        }
    }

    // 将字节数格式化为易读的字符串
    // 参数：字节数
    // 返回：格式化后的字符串（如 "123.4 KB"）
    private func formatBytes(_ bytes: UInt64) -> String {
        let b = Double(bytes)
        
        // 根据大小选择合适的单位
        if b < 1024 {
            // 小于 1KB，显示为字节
            // %6.0f 表示总宽度为 6，不显示小数
            // 后面多加一个空格是因为 "B " 比 "KB" 少一个字符
            return String(format: "%6.0f B ", b)
        } else if b < 1024 * 1024 {
            // 1KB 到 1MB 之间，显示为 KB
            // %6.1f 表示总宽度为 6，保留 1 位小数
            return String(format: "%6.1f KB", b / 1024)
        } else if b < 1024 * 1024 * 1024 {
            // 1MB 到 1GB 之间，显示为 MB
            return String(format: "%6.1f MB", b / (1024 * 1024))
        } else {
            // 大于 1GB，显示为 GB
            // %6.2f 保留 2 位小数，因为 GB 级别需要更高精度
            return String(format: "%6.2f GB", b / (1024 * 1024 * 1024))
        }
    }
}
