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

    /// Resolves the bookmark. A stale bookmark still yields a valid URL (e.g. after the
    /// file was moved or renamed); the caller should then store fresh bookmark data.
    func resolveBookmark() -> (url: URL, isStale: Bool)? {
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withoutUI],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }
        return (url, isStale)
    }
}
