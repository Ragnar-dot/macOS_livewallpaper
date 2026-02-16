import AppKit
import AVFoundation
import Combine

final class WallpaperManager: ObservableObject {
    
    static let shared = WallpaperManager()

    @Published var isPlaying = false

    private var windows: [NSScreen: WallpaperWindow] = [:]
    private var videoViews: [NSScreen: WallpaperVideoView] = [:]
    private var currentURL: URL?
    private var screenObserver: Any?

    private init() {}

    func setup() {
        createWindowsForAllScreens()
        observeScreenChanges()
    }

    // MARK: - Screen Management

    private func createWindowsForAllScreens() {
        // Remove windows for disconnected screens
        let currentScreens = Set(NSScreen.screens)
        for (screen, window) in windows where !currentScreens.contains(screen) {
            window.orderOut(nil)
            windows.removeValue(forKey: screen)
            videoViews.removeValue(forKey: screen)
        }

        // Create windows for new screens
        for screen in NSScreen.screens {
            if windows[screen] == nil {
                let window = WallpaperWindow(screen: screen)
                let videoView = WallpaperVideoView(frame: screen.frame)
                window.contentView = videoView
                window.orderBack(nil)
                windows[screen] = window
                videoViews[screen] = videoView

                // If we have an active video, play it on the new screen too
                if let url = currentURL {
                    videoView.play(url: url)
                    if !isPlaying {
                        videoView.pause()
                    }
                }
            }
        }
    }

    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.createWindowsForAllScreens()
            // Resize existing windows to match new screen frames
            self?.windows.forEach { screen, window in
                window.setFrame(screen.frame, display: true)
            }
        }
    }

    // MARK: - Playback

    func setVideo(url: URL) {
        currentURL = url
        isPlaying = true
        for videoView in videoViews.values {
            videoView.play(url: url)
        }
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    func pause() {
        isPlaying = false
        for videoView in videoViews.values {
            videoView.pause()
        }
    }

    func resume() {
        guard currentURL != nil else { return }
        isPlaying = true
        for videoView in videoViews.values {
            videoView.resume()
        }
    }

    func stop() {
        isPlaying = false
        currentURL = nil
        for videoView in videoViews.values {
            videoView.stop()
        }
    }

    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
