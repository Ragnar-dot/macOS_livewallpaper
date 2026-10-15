# macOS Live Wallpaper

A lightweight macOS menu bar app that plays video files as live wallpapers on your desktop. Supports multiple monitors.

![App Preview](livewallpaper.png)

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.4 or later (to build from source)

## Build & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/Ragnar-dot/macOS_livewallpaper.git
   cd macOS_livewallpaper
   ```
2. Open `LiveWallpaper.xcodeproj` in Xcode.
3. Select your development team under **Signing & Capabilities** (or leave unsigned for local use).
4. Press **Cmd + R** to build and run.

## How to Use

The app runs entirely from the **menu bar** — there is no dock icon or main window.

### Adding a Wallpaper
1. Click the **Live Wallpaper** icon in the menu bar to open the popover.
2. Click **Add Videos…** at the bottom.
3. Select one or more video files (`.mov`, `.mp4`, or `.m4v`) from your Mac.
4. The videos appear in your wallpaper library. Files that are already in the library are skipped.

### Setting a Wallpaper
- Click on any video in the library list to set it as your desktop wallpaper.
- The video starts playing immediately behind all windows on every connected screen.
- Hover over a video for a moment to preview it.

### Playback Controls
- Use the **play/pause** button in the top-right of the popover to toggle playback.
- Playback pauses automatically while the desktop is fully covered (e.g. by a fullscreen app), the screen is locked or the displays are asleep.

### Managing the Library
- Right-click a video to **Show in Finder**, **Rename…** or **Remove from Library**.
- Hover over a video and click **ⓧ** to remove it. Click **Undo** in the notice that appears to bring it back.
- If a video file was moved, it is found automatically. If it was deleted, the entry shows **File not found** — click it to locate the file again.

### Launch at Login
- Click the **gear** icon at the bottom of the popover and enable **Launch at Login**.

### Quitting
- Click the **gear** icon at the bottom of the popover and choose **Quit Live Wallpaper**.

## Features

- Plays video wallpapers behind all desktop windows
- Multi-monitor support — wallpaper plays on all connected screens
- Remembers your last wallpaper and restores it on launch
- Pauses automatically when the wallpaper isn't visible to save battery
- Optional launch at login
- Runs as a menu bar app (no dock icon)
- Lightweight with minimal resource usage

## Supported Formats

| Format | Extension |
|--------|-----------|
| QuickTime Movie | `.mov` |
| MPEG-4 | `.mp4` |
| iTunes Video | `.m4v` |

## License

This project is open source. Feel free to use and modify it.

## 👤 Autor

**Alexander Keterling**

- GitHub: [@Ragnar-dot](https://github.com/Ragnar-dot)
- Website: [loop-expression.de](https://www.loop-expression.de)
