import AppKit
import AVFoundation

final class ThumbnailGenerator {
    static let shared = ThumbnailGenerator()

    private let fileManager = FileManager.default
    private var thumbnailDirectory: URL {
        let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("LiveWallpaper/Thumbnails", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private init() {}

    func generateThumbnail(for itemID: UUID, url: URL) async {
        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 200, height: 200)

        let time = CMTime(seconds: 1, preferredTimescale: 600)

        do {
            let (cgImage, _) = try await generator.image(at: time)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

            guard let tiffData = nsImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else { return }

            let thumbnailURL = thumbnailDirectory.appendingPathComponent("\(itemID.uuidString).png")
            try pngData.write(to: thumbnailURL, options: .atomic)
        } catch {
            print("Failed to generate thumbnail: \(error)")
        }
    }

    func loadThumbnail(for itemID: UUID) -> NSImage? {
        let url = thumbnailDirectory.appendingPathComponent("\(itemID.uuidString).png")
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return NSImage(contentsOf: url)
    }

    func deleteThumbnail(for itemID: UUID) {
        let url = thumbnailDirectory.appendingPathComponent("\(itemID.uuidString).png")
        try? fileManager.removeItem(at: url)
    }
}
