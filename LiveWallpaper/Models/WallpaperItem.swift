import Foundation

struct WallpaperItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var bookmarkData: Data
    let dateAdded: Date

    init(id: UUID = UUID(), name: String, bookmarkData: Data, dateAdded: Date = Date()) {
        self.id = id
        self.name = name
        self.bookmarkData = bookmarkData
        self.dateAdded = dateAdded
    }

    func resolveURL() -> URL? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }

        if isStale {
            // Bookmark is stale; caller should regenerate
            return nil
        }

        return url
    }
}
