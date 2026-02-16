import SwiftUI
import UniformTypeIdentifiers

struct MenuBarPopoverView: View {
    @EnvironmentObject var libraryManager: LibraryManager
    @EnvironmentObject var wallpaperManager: WallpaperManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Live Wallpaper")
                    .font(.headline)
                Spacer()
                PlaybackControlsView()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            Divider()

            // Library
            if libraryManager.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "film")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No wallpapers added")
                        .foregroundStyle(.secondary)
                    Text("Click + to add a video file")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .padding()
            } else {
                LibraryListView()
            }

            Divider()

            // Footer
            HStack {
                Button {
                    addVideo()
                } label: {
                    Label("Add Video", systemImage: "plus")
                }
                .buttonStyle(.borderless)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 280)
    }

    private func addVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            .init(filenameExtension: "mov")!,
            .init(filenameExtension: "mp4")!,
            .init(filenameExtension: "m4v")!,
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Select a video file to use as wallpaper"

        guard panel.runModal() == .OK, let url = panel.url else { return }
        libraryManager.addVideo(from: url)
    }
}
