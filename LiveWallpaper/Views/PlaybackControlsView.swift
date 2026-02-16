import SwiftUI

struct PlaybackControlsView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager

    var body: some View {
        Button {
            wallpaperManager.togglePlayPause()
        } label: {
            Image(systemName: wallpaperManager.isPlaying ? "pause.fill" : "play.fill")
                .font(.body)
        }
        .buttonStyle(.borderless)
        .disabled(LibraryManager.shared.selectedItemID == nil)
    }
}
