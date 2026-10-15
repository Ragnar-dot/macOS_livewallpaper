import SwiftUI

struct WallpaperRowView: View {
    static let height: CGFloat = 66

    @EnvironmentObject var libraryManager: LibraryManager
    @EnvironmentObject var wallpaperManager: WallpaperManager
    let item: WallpaperItem

    @State private var isHovering = false
    @State private var previewURL: URL?
    @State private var isRenaming = false
    @State private var draftName = ""
    @FocusState private var isNameFieldFocused: Bool

    private let thumbnailSize = CGSize(width: 96, height: 54)
    private let thumbnailCornerRadius: CGFloat = 6
    private let previewDelay: Duration = .milliseconds(400)

    private var isActive: Bool {
        libraryManager.selectedItemID == item.id
    }

    private var isMissing: Bool {
        libraryManager.missingItemIDs.contains(item.id)
    }

    var body: some View {
        Button(action: activate) {
            HStack(spacing: 10) {
                thumbnail
                details
                    .opacity(isRenaming ? 0 : 1)
                Spacer(minLength: 0)
            }
            // Keep long names clear of the remove button
            .padding(.trailing, 24)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .leading) {
            if isRenaming {
                renameField
                    .padding(.leading, thumbnailSize.width + 10)
                    .padding(.trailing, 4)
            }
        }
        .overlay(alignment: .trailing) {
            if isHovering && !isRenaming {
                removeButton
            }
        }
        .padding(.horizontal, 6)
        .frame(height: Self.height)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 8))
        .onHover { isHovering = $0 }
        .onDisappear { isHovering = false }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
            // The popover closed or a panel opened: stop the hover preview
            isHovering = false
        }
        .task(id: isHovering) { await updatePreview() }
        .contextMenu { contextMenuItems }
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .animation(.easeOut(duration: 0.15), value: isActive)
    }

    // MARK: - Subviews

    private var thumbnail: some View {
        ZStack {
            ThumbnailView(itemID: item.id)
            if let previewURL {
                VideoPreview(url: previewURL, cornerRadius: thumbnailCornerRadius)
            }
            if isMissing {
                Rectangle()
                    .fill(.black.opacity(0.55))
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .frame(width: thumbnailSize.width, height: thumbnailSize.height)
        .clipShape(RoundedRectangle(cornerRadius: thumbnailCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: thumbnailCornerRadius)
                .strokeBorder(
                    isActive ? Color.accentColor : Color.primary.opacity(0.1),
                    lineWidth: isActive ? 2 : 1
                )
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(item.name)
                .font(.callout)
                .fontWeight(isActive ? .semibold : .regular)
                .foregroundStyle(isMissing ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.middle)
            statusLabel
                .font(.caption)
        }
    }

    @ViewBuilder
    private var statusLabel: some View {
        if isMissing {
            Label("File not found · Click to locate", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
        } else if isActive {
            Label(
                wallpaperManager.isPlaying ? LocalizedStringKey("Now Playing") : "Paused",
                systemImage: wallpaperManager.isPlaying ? "play.fill" : "pause.fill"
            )
            .foregroundStyle(Color.accentColor)
        }
    }

    private var rowBackground: Color {
        if isActive {
            return .accentColor.opacity(0.14)
        }
        return isHovering ? .primary.opacity(0.06) : .clear
    }

    private var renameField: some View {
        TextField("Name", text: $draftName)
            .textFieldStyle(.roundedBorder)
            .font(.callout)
            .focused($isNameFieldFocused)
            .onSubmit(commitRename)
            .onExitCommand(perform: cancelRename)
            .onChange(of: isNameFieldFocused) { _, isFocused in
                if !isFocused {
                    commitRename()
                }
            }
    }

    private var removeButton: some View {
        Button {
            libraryManager.remove(item)
        } label: {
            Label("Remove from Library", systemImage: "xmark.circle.fill")
                .labelStyle(.iconOnly)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .padding(.trailing, 4)
        .transition(.opacity)
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        Button("Set as Wallpaper", action: activate)
            .disabled(isMissing || (isActive && wallpaperManager.isPlaying))

        if isMissing {
            Button("Locate File…") { locate(thenSelect: false) }
        } else {
            Button("Show in Finder", action: showInFinder)
        }

        Button("Rename…", action: beginRename)

        Divider()

        Button("Remove from Library", role: .destructive) {
            libraryManager.remove(item)
        }
    }

    // MARK: - Actions

    private func activate() {
        if isMissing {
            locate(thenSelect: true)
        } else {
            libraryManager.select(item)
        }
    }

    private func locate(thenSelect: Bool) {
        let message = "Locate “\(item.name)”"
        guard let url = VideoFilePicker.chooseFiles(allowsMultipleSelection: false, message: message).first else {
            return
        }
        libraryManager.relink(item, to: url)
        if thenSelect {
            libraryManager.select(item)
        }
    }

    private func showInFinder() {
        guard let url = libraryManager.resolveURL(for: item) else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func beginRename() {
        draftName = item.name
        isRenaming = true
        DispatchQueue.main.async {
            isNameFieldFocused = true
        }
    }

    private func commitRename() {
        guard isRenaming else { return }
        isRenaming = false
        libraryManager.rename(item, to: draftName)
    }

    private func cancelRename() {
        isRenaming = false
    }

    private func updatePreview() async {
        guard isHovering, !isMissing else {
            previewURL = nil
            return
        }
        // Short delay so moving the pointer across the list doesn't start every video
        try? await Task.sleep(for: previewDelay)
        guard !Task.isCancelled else { return }
        previewURL = libraryManager.resolveURL(for: item)
    }
}

struct ThumbnailView: View {
    let itemID: UUID
    @ObservedObject private var thumbnails = ThumbnailGenerator.shared

    var body: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.2))
            .overlay {
                if let image = thumbnails.images[itemID] {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "film")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .clipped()
            .task(id: itemID) {
                thumbnails.loadThumbnail(for: itemID)
            }
    }
}

/// Muted, looping inline playback used for the hover preview.
private struct VideoPreview: NSViewRepresentable {
    let url: URL
    let cornerRadius: CGFloat

    func makeCoordinator() -> LoopingVideoPlayer {
        LoopingVideoPlayer(url: url)
    }

    func makeNSView(context: Context) -> WallpaperVideoView {
        let view = WallpaperVideoView(frame: .zero)
        view.layer?.cornerRadius = cornerRadius
        view.layer?.masksToBounds = true
        view.player = context.coordinator.player
        context.coordinator.play()
        return view
    }

    func updateNSView(_ nsView: WallpaperVideoView, context: Context) {}

    static func dismantleNSView(_ nsView: WallpaperVideoView, coordinator: LoopingVideoPlayer) {
        coordinator.pause()
        nsView.player = nil
    }
}
