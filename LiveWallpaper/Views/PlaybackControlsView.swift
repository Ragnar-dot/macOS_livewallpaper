import SwiftUI

struct PlaybackControlsView: View {
    @EnvironmentObject var wallpaperManager: WallpaperManager

    var body: some View {
        Button {
            wallpaperManager.togglePlayPause()
        } label: {
            Label(
                wallpaperManager.isPlaying ? "Pause" : "Play",
                systemImage: wallpaperManager.isPlaying ? "pause.circle.fill" : "play.circle.fill"
            )
            .labelStyle(.iconOnly)
            .font(.system(size: 26))
            .symbolRenderingMode(.hierarchical)
            .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.borderless)
        .disabled(wallpaperManager.currentURL == nil)
    }
}
