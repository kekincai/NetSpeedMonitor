# NetSpeedMonitor

A simple, lightweight macOS menu bar application that monitors and displays your current network upload and download speeds.

## Features

- **Real-time Monitoring**: Displays accurate upload and download speeds.
- **Fixed Width UI**: Designed to sit neatly in your menu bar without jittering as numbers change.
- **Adaptive Units**: Automatically switches between B, KB, and MB/s (with a preference for clarity).
- **Native Look**: clean, system-aligned aesthetics.

## Installation & Running

This is a Swift Package Manager executable.

1.  Clone the repository.
2.  Navigate to the directory:
    ```bash
    cd NetSpeedMonitor
    ```
3.  Run the application:
    ```bash
    swift run
    ```

## App Icon

An `AppIcon.png` is included in the project root. To apply it to the executable for a more permanent installation:
1. Create a `NetSpeedMonitor.app` bundle structure or use a tool like `appify`.
2. Or simply use the executable as is.

## Requirements

- macOS 13.0 or later
