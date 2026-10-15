import Foundation
import Combine

final class LibraryManager: ObservableObject {
    static let shared = LibraryManager()

    /// A transient message shown at the bottom of the popover.
    struct Notice: Identifiable {
        enum Kind {
            case removed(item: WallpaperItem, index: Int, wasSelected: Bool)
            case info
        }

        let id = UUID()
        let message: String
        let kind: Kind

        var isUndoable: Bool {
            if case .removed = kind { return true }
            return false
        }
    }

    @Published var items: [WallpaperItem] = []
    @Published var selectedItemID: UUID?
    /// Items whose video file can no longer be found on disk.
    @Published private(set) var missingItemIDs: Set<UUID> = []
    @Published private(set) var notice: Notice?

    var selectedItem: WallpaperItem? {
        items.first { $0.id == selectedItemID }
    }

    private let fileManager = FileManager.default
    private var noticeTask: Task<Void, Never>?
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

        if let lastID = UserDefaults.standard.string(forKey: "lastWallpaperID"),
           let uuid = UUID(uuidString: lastID),
           items.contains(where: { $0.id == uuid }) {
            selectedItemID = uuid
        }

        refreshAvailability()
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
        } else {
            UserDefaults.standard.removeObject(forKey: "lastWallpaperID")
        }
    }

    // MARK: - File Resolution

    /// Resolves an item's file, refreshing stale bookmarks and tracking missing files.
    func resolveURL(for item: WallpaperItem) -> URL? {
        // Views may hold an outdated copy (e.g. after relinking), so prefer the stored item
        let item = items.first { $0.id == item.id } ?? item
        guard let (url, isStale) = item.resolveBookmark(),
              fileManager.fileExists(atPath: url.path) else {
            missingItemIDs.insert(item.id)
            return nil
        }

        missingItemIDs.remove(item.id)

        if isStale,
           let freshData = try? url.bookmarkData(),
           let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].bookmarkData = freshData
            save()
        }

        return url
    }

    /// Re-checks every item's file and regenerates thumbnails that are missing or outdated.
    func refreshAvailability() {
        for item in items {
            if let url = resolveURL(for: item) {
                ThumbnailGenerator.shared.ensureThumbnail(for: item.id, url: url)
            }
        }
    }

    // MARK: - Editing

    func addVideos(from urls: [URL]) {
        var knownPaths = Set(items.compactMap { resolveURL(for: $0).map(canonicalPath) })
        var duplicateNames: [String] = []

        for url in urls {
            let name = url.deletingPathExtension().lastPathComponent
            guard knownPaths.insert(canonicalPath(url)).inserted else {
                duplicateNames.append(name)
                continue
            }

            do {
                let bookmarkData = try url.bookmarkData(
                    options: [],
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
                let item = WallpaperItem(name: name, bookmarkData: bookmarkData)
                items.append(item)
                ThumbnailGenerator.shared.ensureThumbnail(for: item.id, url: url)
            } catch {
                print("Failed to create bookmark: \(error)")
            }
        }

        save()

        if duplicateNames.count == 1 {
            post(Notice(message: "“\(duplicateNames[0])” is already in your library", kind: .info))
        } else if duplicateNames.count > 1 {
            post(Notice(message: "\(duplicateNames.count) videos are already in your library", kind: .info))
        }
    }

    func remove(_ item: WallpaperItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let wasSelected = selectedItemID == item.id

        items.remove(at: index)
        missingItemIDs.remove(item.id)
        if wasSelected {
            selectedItemID = nil
            WallpaperManager.shared.stop()
        }
        save()

        // The thumbnail is kept until the undo window has passed.
        post(Notice(
            message: "Removed “\(item.name)”",
            kind: .removed(item: item, index: index, wasSelected: wasSelected)
        ))
    }

    func undoRemove() {
        guard case let .removed(item, index, wasSelected) = notice?.kind else { return }
        noticeTask?.cancel()
        notice = nil

        items.insert(item, at: min(index, items.count))
        if wasSelected {
            select(item)
        } else {
            save()
        }
        _ = resolveURL(for: item)
    }

    func rename(_ item: WallpaperItem, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].name = trimmed
        save()
    }

    /// Points an item at a new file, e.g. after the original was moved to another volume or deleted.
    func relink(_ item: WallpaperItem, to url: URL) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        do {
            items[index].bookmarkData = try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            print("Failed to create bookmark: \(error)")
            return
        }

        missingItemIDs.remove(item.id)
        save()
        ThumbnailGenerator.shared.regenerateThumbnail(for: item.id, url: url)

        if selectedItemID == item.id {
            WallpaperManager.shared.setVideo(url: url)
        }
    }

    @discardableResult
    func select(_ item: WallpaperItem) -> Bool {
        guard let url = resolveURL(for: item) else { return false }
        selectedItemID = item.id
        WallpaperManager.shared.setVideo(url: url)
        save()
        return true
    }

    // MARK: - Notices

    private func post(_ newNotice: Notice) {
        dismissNotice()
        notice = newNotice
        noticeTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            self?.dismissNotice()
        }
    }

    /// Hides the current notice and finalizes a pending removal.
    func dismissNotice() {
        noticeTask?.cancel()
        noticeTask = nil
        if case let .removed(item, _, _) = notice?.kind {
            ThumbnailGenerator.shared.deleteThumbnail(for: item.id)
        }
        notice = nil
    }

    private func canonicalPath(_ url: URL) -> String {
        url.standardizedFileURL.resolvingSymlinksInPath().path
    }
}
