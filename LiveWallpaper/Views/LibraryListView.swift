import SwiftUI

struct LibraryListView: View {
    @EnvironmentObject var libraryManager: LibraryManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(libraryManager.items) { item in
                    WallpaperRowView(item: item)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 300)
    }
}
