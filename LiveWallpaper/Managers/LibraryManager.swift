import Foundation
import Combine

final class LibraryManager: ObservableObject {
    static let shared = LibraryManager()

    @Published var items: [WallpaperItem] = []
    @Published var selectedItemID: UUID?

    private let fileManager = FileManager.default
    private var libraryURL: URL {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = support.appendingPathComponent("LiveWallpaper", isDirectory: true)
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("library.json")
    }

    private init() {}

    func load() {
        guard fileManager.fileExists(atPath: libraryURL.path) else { return }
        do {
            let data = try Data(contentsOf: libraryURL)
            items = try JSONDecoder().decode([WallpaperItem].self, from: data)
        } catch {
            print("Failed to load library: \(error)")
        }

        if let lastID = UserDefaults.standard.string(forKey: "lastWallpaperID") {
            selectedItemID = UUID(uuidString: lastID)
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: libraryURL, options: .atomic)
        } catch {
            print("Failed to save library: \(error)")
        }

        if let id = selectedItemID {
            UserDefaults.standard.set(id.uuidString, forKey: "lastWallpaperID")
        }
    }

    func addVideo(from url: URL) {
        do {
            let bookmarkData = try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            let name = url.deletingPathExtension().lastPathComponent
            let item = WallpaperItem(name: name, bookmarkData: bookmarkData)
            items.append(item)
            save()

            Task {
                await ThumbnailGenerator.shared.generateThumbnail(for: item.id, url: url)
            }
        } catch {
            print("Failed to create bookmark: \(error)")
        }
    }

    func remove(_ item: WallpaperItem) {
        items.removeAll { $0.id == item.id }
        if selectedItemID == item.id {
            selectedItemID = nil
            WallpaperManager.shared.stop()
        }
        save()
        ThumbnailGenerator.shared.deleteThumbnail(for: item.id)
    }

    func select(_ item: WallpaperItem) {
        guard let url = item.resolveURL() else { return }
        selectedItemID = item.id
        WallpaperManager.shared.setVideo(url: url)
        save()
    }
}
