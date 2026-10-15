import AppKit
import AVFoundation
import Combine

final class ThumbnailGenerator: ObservableObject {
    static let shared = ThumbnailGenerator()

    /// Loaded thumbnails; views observe this so new thumbnails appear without reopening the popover.
    @Published private(set) var images: [UUID: NSImage] = [:]

    /// Thumbnails up to this size were made for the old, smaller list rows and look blurry now.
    private let legacyMaxPixelSize = 200
    private let maxPixelSize = CGSize(width: 480, height: 480)

    private let fileManager = FileManager.default
    private var inFlight: Set<UUID> = []
    private var thumbnailDirectory: URL {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("LiveWallpaper/Thumbnails", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private init() {}

    /// Generates a thumbnail unless an up-to-date one already exists on disk.
    func ensureThumbnail(for itemID: UUID, url: URL) {
        guard !hasCurrentThumbnail(for: itemID) else { return }
        regenerateThumbnail(for: itemID, url: url)
    }

    func regenerateThumbnail(for itemID: UUID, url: URL) {
        guard inFlight.insert(itemID).inserted else { return }
        Task {
            await generateThumbnail(for: itemID, url: url)
            await MainActor.run { _ = self.inFlight.remove(itemID) }
        }
    }

    private func generateThumbnail(for itemID: UUID, url: URL) async {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = maxPixelSize

        let time = CMTime(seconds: 1, preferredTimescale: 600)

        do {
            let (cgImage, _) = try await generator.image(at: time)
            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            guard let pngData = bitmap.representation(using: .png, properties: [:]) else { return }
            try pngData.write(to: thumbnailURL(for: itemID), options: .atomic)

            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            await MainActor.run { self.images[itemID] = nsImage }
        } catch {
            print("Failed to generate thumbnail: \(error)")
        }
    }

    /// Loads a thumbnail from disk into `images` if it is not cached yet.
    func loadThumbnail(for itemID: UUID) {
        guard images[itemID] == nil else { return }
        let url = thumbnailURL(for: itemID)
        guard fileManager.fileExists(atPath: url.path) else { return }
        images[itemID] = NSImage(contentsOf: url)
    }

    func deleteThumbnail(for itemID: UUID) {
        images[itemID] = nil
        try? fileManager.removeItem(at: thumbnailURL(for: itemID))
    }

    private func thumbnailURL(for itemID: UUID) -> URL {
        thumbnailDirectory.appendingPathComponent("\(itemID.uuidString).png")
    }

    private func hasCurrentThumbnail(for itemID: UUID) -> Bool {
        guard let source = CGImageSourceCreateWithURL(thumbnailURL(for: itemID) as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return false
        }
        return max(width, height) > legacyMaxPixelSize
    }
}
