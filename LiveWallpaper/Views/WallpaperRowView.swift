import SwiftUI

struct WallpaperRowView: View {
    @EnvironmentObject var libraryManager: LibraryManager
    let item: WallpaperItem

    private var isSelected: Bool {
        libraryManager.selectedItemID == item.id
    }

    var body: some View {
        HStack(spacing: 8) {
            // Thumbnail
            ThumbnailView(itemID: item.id)
                .frame(width: 48, height: 28)
                .cornerRadius(4)

            // Name
            Text(item.name)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            // Delete button
            Button {
                libraryManager.remove(item)
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .opacity(isSelected ? 0.6 : 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            libraryManager.select(item)
        }
    }
}

struct ThumbnailView: View {
    let itemID: UUID
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .overlay {
                        Image(systemName: "film")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .clipped()
        .task {
            image = ThumbnailGenerator.shared.loadThumbnail(for: itemID)
        }
    }
}
