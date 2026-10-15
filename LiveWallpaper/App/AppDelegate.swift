import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        LibraryManager.shared.load()
        WallpaperManager.shared.setup()

        // Restore last played wallpaper
        if let item = LibraryManager.shared.selectedItem {
            LibraryManager.shared.select(item)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Finalize a removal that is still waiting for undo
        LibraryManager.shared.dismissNotice()
        LibraryManager.shared.save()
    }
}
