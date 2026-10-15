import SwiftUI

struct LibraryListView: View {
    @EnvironmentObject var libraryManager: LibraryManager

    private let spacing: CGFloat = 4
    private let padding: CGFloat = 8
    private let maxHeight: CGFloat = 390

    var body: some View {
        ScrollView {
            LazyVStack(spacing: spacing) {
                ForEach(libraryManager.items) { item in
                    WallpaperRowView(item: item)
                }
            }
            .padding(padding)
        }
        // Grow with the library, then scroll
        .frame(height: listHeight)
    }

    private var listHeight: CGFloat {
        let count = CGFloat(libraryManager.items.count)
        let content = count * WallpaperRowView.height + max(count - 1, 0) * spacing + 2 * padding
        return min(content, maxHeight)
    }
}
