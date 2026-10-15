import SwiftUI
import UniformTypeIdentifiers

struct MenuBarPopoverView: View {
    @EnvironmentObject var libraryManager: LibraryManager
    @EnvironmentObject var wallpaperManager: WallpaperManager
    @State private var launchAtLogin = LoginItemManager.isEnabled

    var body: some View {
        VStack(spacing: 0) {
            NowPlayingHeader()
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

            Divider()

            // Library
            if libraryManager.items.isEmpty {
                emptyState
            } else {
                LibraryListView()
            }

            if let notice = libraryManager.notice {
                NoticeBanner(notice: notice)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            Divider()

            footer
        }
        .frame(width: 360)
        .animation(.easeOut(duration: 0.2), value: libraryManager.notice?.id)
        .onAppear(perform: refresh)
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification)) { _ in
            // The popover is shown again: files or login item state may have changed meanwhile
            refresh()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "film.stack")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            VStack(spacing: 3) {
                Text("No wallpapers yet")
                    .font(.headline)
                Text("Add a .mov, .mp4 or .m4v video to get started.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Button("Add Videos…", action: addVideos)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
    }

    private var footer: some View {
        HStack {
            Button(action: addVideos) {
                Label("Add Videos…", systemImage: "plus")
            }
            .buttonStyle(.borderless)

            Spacer()

            Menu {
                Toggle("Launch at Login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { _ in
                        LoginItemManager.toggle()
                        launchAtLogin = LoginItemManager.isEnabled
                    }
                ))

                Divider()

                Button("Quit Live Wallpaper") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .labelStyle(.iconOnly)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func refresh() {
        libraryManager.refreshAvailability()
        launchAtLogin = LoginItemManager.isEnabled
    }

    private func addVideos() {
        let urls = VideoFilePicker.chooseFiles(
            allowsMultipleSelection: true,
            message: "Select video files to use as wallpaper"
        )
        guard !urls.isEmpty else { return }
        libraryManager.addVideos(from: urls)
    }
}

private struct NowPlayingHeader: View {
    @EnvironmentObject var libraryManager: LibraryManager
    @EnvironmentObject var wallpaperManager: WallpaperManager

    var body: some View {
        HStack(spacing: 10) {
            if let item = libraryManager.selectedItem {
                ThumbnailView(itemID: item.id)
                    .frame(width: 64, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                VStack(alignment: .leading, spacing: 1) {
                    Text(status(for: item))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Live Wallpaper")
                        .font(.headline)
                    Text("No wallpaper selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            PlaybackControlsView()
        }
        .frame(minHeight: 36)
    }

    private func status(for item: WallpaperItem) -> LocalizedStringKey {
        if libraryManager.missingItemIDs.contains(item.id) {
            return "File not found"
        }
        return wallpaperManager.isPlaying ? "Now Playing" : "Paused"
    }
}

private struct NoticeBanner: View {
    @EnvironmentObject var libraryManager: LibraryManager
    let notice: LibraryManager.Notice

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: notice.isUndoable ? "xmark.circle" : "info.circle")
                .foregroundStyle(.secondary)
            Text(notice.message)
                .font(.callout)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 4)
            if notice.isUndoable {
                Button("Undo") {
                    libraryManager.undoRemove()
                }
                .buttonStyle(.borderless)
                .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8))
    }
}

enum VideoFilePicker {
    static let contentTypes: [UTType] = ["mov", "mp4", "m4v"].compactMap { UTType(filenameExtension: $0) }

    static func chooseFiles(allowsMultipleSelection: Bool, message: String) -> [URL] {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = contentTypes
        panel.allowsMultipleSelection = allowsMultipleSelection
        panel.canChooseDirectories = false
        panel.message = message

        guard panel.runModal() == .OK else { return [] }
        return panel.urls
    }
}
