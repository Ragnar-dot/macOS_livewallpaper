import AppKit

final class WallpaperWindow: NSPanel {
    init(screen: NSScreen) {
        super.init(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Place below desktop icons but above desktop picture
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) - 1)

        // Click-through: let mouse events pass to Finder/desktop
        ignoresMouseEvents = true

        // Critical: keep visible when app loses focus
        hidesOnDeactivate = false

        // Visible on all Spaces, stationary, not in Expose/Mission Control
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        // No shadow, transparent background
        hasShadow = false
        backgroundColor = .clear
        isOpaque = false

        // Do not show in window menu
        isExcludedFromWindowsMenu = true
    }
}
