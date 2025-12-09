import SwiftUI
import AppKit

// @main 标记表示这是应用程序的入口点
@main
struct NetSpeedApp: App {
    // @NSApplicationDelegateAdaptor 用于在 SwiftUI App 中使用传统的 AppDelegate
    // 这样可以使用 NSStatusItem 来创建菜单栏图标
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // MenuBarExtra 用于创建菜单栏应用
        // 当用户点击菜单栏图标时，显示详细统计信息
        MenuBarExtra {
            if let stats = appDelegate.stats {
                DetailedStatsView(stats: stats)
            }
        } label: {
            // 这个 label 不会被使用，因为我们在 AppDelegate 中自定义了按钮
            EmptyView()
        }
    }
}

// AppDelegate 类负责管理应用程序的生命周期和菜单栏图标
class AppDelegate: NSObject, NSApplicationDelegate {
    // statusItem 是菜单栏中的图标项
    var statusItem: NSStatusItem?
    // stats 是网络统计数据的管理对象
    var stats: NetworkStats?
    // popover 用于显示详细信息窗口
    var popover: NSPopover?
    
    // 应用程序启动完成后调用此方法
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 在系统状态栏创建一个可变长度的状态项
        // NSStatusItem.variableLength 表示宽度会根据内容自动调整
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // 检查状态项的按钮是否存在
        if let button = statusItem?.button {
            // 初始化时就设置正确的格式，避免启动时字体大小跳变
            updateStatusBar(download: "   0.0 KB", upload: "   0.0 KB")
            // 设置按钮点击事件
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // 创建网络统计对象
        stats = NetworkStats()
        // 设置回调函数，当网络速度更新时调用 updateStatusBar
        // [weak self] 避免循环引用导致内存泄漏
        stats?.onUpdate = { [weak self] download, upload in
            self?.updateStatusBar(download: download, upload: upload)
        }
        
        // 创建 popover 用于显示详细信息
        setupPopover()
    }
    
    // 设置 popover 弹出窗口
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 500)
        popover?.behavior = .transient  // 点击外部自动关闭
        
        if let stats = stats {
            let detailView = DetailedStatsView(stats: stats)
            popover?.contentViewController = NSHostingController(rootView: detailView)
        }
    }
    
    // 切换 popover 显示/隐藏
    @objc func togglePopover() {
        guard let button = statusItem?.button else { return }
        
        if let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    // 更新状态栏显示的网络速度
    func updateStatusBar(download: String, upload: String) {
        // guard let 用于安全解包可选值，如果为 nil 则直接返回
        guard let button = statusItem?.button else { return }
        
        // 构建显示文本，使用换行符分隔上下行
        // ↓ 表示下载，↑ 表示上传
        let text = "↓\(download)\n↑\(upload)"
        
        // 创建段落样式对象，用于控制文本布局
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right              // 文字右对齐
        paragraphStyle.lineSpacing = -2                // 行间距为 -2，让两行更紧凑
        paragraphStyle.paragraphSpacing = 0            // 段落间距为 0
        paragraphStyle.lineHeightMultiple = 0.9        // 行高倍数为 0.9，进一步压缩高度
        
        // 创建文本属性字典
        let attributes: [NSAttributedString.Key: Any] = [
            // 使用等宽字体，大小 9pt，这样数字对齐更整齐
            .font: NSFont.monospacedSystemFont(ofSize: 9, weight: .regular),
            // 应用段落样式
            .paragraphStyle: paragraphStyle,
            // 基线偏移 -6，让文字稍微下移，实现垂直居中
            .baselineOffset: -6
        ]
        
        // 创建带属性的字符串并设置到按钮上
        button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
    }
    
    // @objc 标记表示此方法可以被 Objective-C 运行时调用
    // 这是因为 NSMenuItem 的 action 需要 Objective-C 兼容的方法
    @objc func quit() {
        // 终止应用程序
        NSApplication.shared.terminate(nil)
    }
}
