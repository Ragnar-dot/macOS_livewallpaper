import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        LibraryManager.shared.load()
        WallpaperManager.shared.setup()

        // Restore last played wallpaper
        if let lastID = UserDefaults.standard.string(forKey: "lastWallpaperID"),
           let uuid = UUID(uuidString: lastID),
           let item = LibraryManager.shared.items.first(where: { $0.id == uuid }),
           let url = item.resolveURL() {
            WallpaperManager.shared.setVideo(url: url)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        LibraryManager.shared.save()
    }
}
