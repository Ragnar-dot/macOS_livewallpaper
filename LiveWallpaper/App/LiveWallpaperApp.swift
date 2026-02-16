import SwiftUI

@main
struct LiveWallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var libraryManager = LibraryManager.shared
    @StateObject private var wallpaperManager = WallpaperManager.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarPopoverView()
                .environmentObject(libraryManager)
                .environmentObject(wallpaperManager)
        } label: {
            Image(systemName: "play.rectangle.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
