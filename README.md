# NetSpeedMonitor - 网络速度监控

一个简洁、轻量的 macOS 菜单栏应用，实时监控并显示网络上传和下载速度。

## 功能特点

- **实时监控**：准确显示上传和下载速度
- **固定宽度显示**：数字变化时不会抖动，整齐地显示在菜单栏中
- **自适应单位**：自动在 B、KB、MB、GB 之间切换，保持清晰易读
- **原生外观**：简洁的系统风格设计
- **两行显示**：上下行速度分两行显示，一目了然

## 安装和运行

这是一个使用 Swift Package Manager 构建的可执行程序。

1. 克隆仓库：
   ```bash
   git clone <repository-url>
   ```

2. 进入项目目录：
   ```bash
   cd NetSpeedMonitor
   ```

3. 运行应用：
   ```bash
   swift run
   ```

4. 编译发布版本（可选）：
   ```bash
   swift build -c release
   ```
   编译后的可执行文件位于 `.build/release/NetSpeedMonitor`

## 显示说明

### 菜单栏显示
菜单栏显示格式：
```
↓  123.4 KB/s
↑   45.6 KB/s
```

- ↓ 表示下载速度
- ↑ 表示上传速度
- 使用等宽字体，数字右对齐，保持显示稳定

### 详细信息面板
点击菜单栏图标，会弹出详细信息面板，包含：

- **实时速度**：当前上传和下载速度
- **速度图表**：最近 20 秒的速度变化趋势
- **网络信息**：WiFi SSID、本地 IP、外网 IP、Ping 延迟
- **流量统计**：今日使用流量、本月使用流量
- **Top 进程**：占用流量最多的应用程序（实时监控）
- **网络健康**：网络状态、丢包率、WiFi 信号强度

## 应用图标

项目根目录包含 `AppIcon.png` 图标文件。如需创建完整的 .app 应用包：

1. 使用 `appify` 等工具将可执行文件打包为 .app
2. 或直接使用编译后的可执行文件

## 系统要求

- macOS 13.0 或更高版本
- Swift 5.9 或更高版本

## 代码结构

```
Sources/NetSpeedMonitor/
├── NetSpeedApp.swift      # 应用主入口和菜单栏 UI
└── NetworkStats.swift     # 网络速度监控和计算逻辑
```

### 主要组件说明

- **NetSpeedApp.swift**：使用 AppDelegate 和 NSStatusItem 创建菜单栏图标，处理 UI 显示
- **NetworkStats.swift**：通过系统 API 获取网络接口数据，计算实时速度

## 技术细节

- 使用 `getifaddrs()` 系统调用获取网络接口统计信息
- 每秒更新一次速度数据
- 使用 NSAttributedString 实现精确的文本布局控制
- 过滤回环接口，只统计真实网络流量
- 使用 `nettop` 命令监控进程级别的网络使用情况
- 备用方案使用 `lsof` 命令获取网络连接信息

## 进程监控说明

应用使用 macOS 系统自带的 `nettop` 命令来获取每个进程的网络流量数据。`nettop` 会显示：
- 每个进程的下载速度（bytes_in）
- 每个进程的上传速度（bytes_out）
- 自动合并同名进程的流量统计

如果 `nettop` 不可用，会自动切换到备用方案（使用 `lsof` 显示网络连接数）。

**注意**：进程监控每 3 秒更新一次，以减少系统资源消耗。

## 许可证

MIT License
