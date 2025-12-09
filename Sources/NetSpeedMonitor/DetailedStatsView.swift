import SwiftUI

// 详细统计信息视图
struct DetailedStatsView: View {
    @ObservedObject var stats: NetworkStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 当前速度显示
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Text("⬇")
                    Text(stats.downloadSpeed)
                        .monospacedDigit()
                }
                HStack(spacing: 4) {
                    Text("⬆")
                    Text(stats.uploadSpeed)
                        .monospacedDigit()
                }
            }
            .font(.system(size: 16, weight: .medium))
            
            // 速度图表
            HStack(spacing: 4) {
                Text("┃")
                SpeedChartView(history: stats.speedHistory)
                Text("┃")
                Text("最近 20 秒")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // 网络信息
            VStack(alignment: .leading, spacing: 6) {
                if let ssid = stats.wifiSSID {
                    HStack {
                        Text("SSID：")
                            .foregroundColor(.secondary)
                        Text(ssid)
                    }
                }
                
                HStack {
                    Text("IP：")
                        .foregroundColor(.secondary)
                    Text(stats.localIP)
                }
                
                HStack {
                    Text("外网：")
                        .foregroundColor(.secondary)
                    Text(stats.publicIP)
                }
                
                HStack {
                    Text("Ping：")
                        .foregroundColor(.secondary)
                    Text(stats.pingTime)
                }
            }
            .font(.system(size: 12))
            
            Divider()
            
            // 流量统计
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("今日使用：")
                        .foregroundColor(.secondary)
                    Text(stats.todayUsage)
                }
                
                HStack {
                    Text("本月使用：")
                        .foregroundColor(.secondary)
                    Text(stats.monthUsage)
                }
            }
            .font(.system(size: 12))
            
            Divider()
            
            // Top 流量进程
            VStack(alignment: .leading, spacing: 4) {
                Text("Top 流量进程：")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                ForEach(stats.topProcesses, id: \.name) { process in
                    HStack {
                        Text(process.name)
                            .frame(width: 120, alignment: .leading)
                        Spacer()
                        if process.download > 0 {
                            Text("⬇ \(formatSpeed(process.download))")
                                .monospacedDigit()
                        }
                        if process.upload > 0 {
                            Text("⬆ \(formatSpeed(process.upload))")
                                .monospacedDigit()
                        }
                    }
                    .font(.system(size: 11))
                }
            }
            
            Divider()
            
            // 网络健康
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("网络健康：")
                        .foregroundColor(.secondary)
                    Text(stats.networkHealth)
                        .foregroundColor(healthColor(stats.networkHealth))
                }
                
                HStack(spacing: 20) {
                    HStack {
                        Text("丢包：")
                            .foregroundColor(.secondary)
                        Text(stats.packetLoss)
                    }
                    
                    if let signal = stats.wifiSignal {
                        HStack {
                            Text("信号：")
                                .foregroundColor(.secondary)
                            Text(signal)
                        }
                    }
                }
            }
            .font(.system(size: 12))
            
            Divider()
            
            // 退出按钮
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(12)
        .frame(width: 280)
    }
    
    // 格式化速度显示
    private func formatSpeed(_ bytesPerSecond: UInt64) -> String {
        let b = Double(bytesPerSecond)
        if b < 1024 {
            return String(format: "%.0f B/s", b)
        } else if b < 1024 * 1024 {
            return String(format: "%.1f KB/s", b / 1024)
        } else {
            return String(format: "%.1f MB/s", b / (1024 * 1024))
        }
    }
    
    // 根据健康状态返回颜色
    private func healthColor(_ health: String) -> Color {
        switch health {
        case "良好": return .green
        case "一般": return .orange
        case "较差": return .red
        default: return .primary
        }
    }
}

// 速度图表视图
struct SpeedChartView: View {
    let history: [Double]
    
    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<history.count, id: \.self) { index in
                Text(barChar(for: history[index]))
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
            }
        }
    }
    
    // 根据速度值返回对应的条形字符
    private func barChar(for value: Double) -> String {
        let chars = ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
        let index = min(Int(value * Double(chars.count)), chars.count - 1)
        return chars[max(0, index)]
    }
}
