import AppKit
import AVFoundation
import Combine

final class WallpaperManager: ObservableObject {

    static let shared = WallpaperManager()

    /// The user's play/pause choice. Playback is additionally suspended while the
    /// wallpaper can't be seen (covered, screen locked, displays asleep).
    @Published var isPlaying = false
    @Published private(set) var currentURL: URL?

    private var windows: [NSScreen: WallpaperWindow] = [:]
    private var videoViews: [NSScreen: WallpaperVideoView] = [:]
    /// One player feeds every screen, so the video is decoded only once and stays in sync.
    private var videoPlayer: LoopingVideoPlayer?
    private var observers: [(center: NotificationCenter, token: NSObjectProtocol)] = []

    private var screensAreAsleep = false
    private var screenIsLocked = false
    private var sessionIsInactive = false
    private var pendingOcclusionUpdate: DispatchWorkItem?

    /// Occlusion state flickers while windows move over the desktop, so pausing waits for it to settle.
    private let occlusionPauseDelay: TimeInterval = 0.75

    private init() {}

    func setup() {
        createWindowsForAllScreens()
        observeScreenChanges()
        observeVisibilityChanges()
    }

    // MARK: - Screen Management

    private func createWindowsForAllScreens() {
        // Remove windows for disconnected screens
        let currentScreens = Set(NSScreen.screens)
        for (screen, window) in windows where !currentScreens.contains(screen) {
            window.orderOut(nil)
            videoViews[screen]?.player = nil
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

                // If we have an active video, show it on the new screen too
                videoView.player = videoPlayer?.player
            }
        }

        updatePlayback()
    }

    private func observeScreenChanges() {
        observe(NSApplication.didChangeScreenParametersNotification) { [weak self] _ in
            self?.createWindowsForAllScreens()
            // Resize existing windows to match new screen frames
            self?.windows.forEach { screen, window in
                window.setFrame(screen.frame, display: true)
            }
        }
    }

    // MARK: - Visibility

    private func observeVisibilityChanges() {
        observe(NSWindow.didChangeOcclusionStateNotification) { [weak self] notification in
            guard let self, let window = notification.object as? WallpaperWindow else { return }
            self.pendingOcclusionUpdate?.cancel()
            if window.occlusionState.contains(.visible) {
                self.updatePlayback()
            } else {
                let update = DispatchWorkItem { [weak self] in self?.updatePlayback() }
                self.pendingOcclusionUpdate = update
                DispatchQueue.main.asyncAfter(deadline: .now() + self.occlusionPauseDelay, execute: update)
            }
        }

        let workspace = NSWorkspace.shared.notificationCenter
        observe(NSWorkspace.screensDidSleepNotification, on: workspace) { [weak self] _ in
            self?.screensAreAsleep = true
            self?.updatePlayback()
        }
        observe(NSWorkspace.screensDidWakeNotification, on: workspace) { [weak self] _ in
            self?.screensAreAsleep = false
            self?.updatePlayback()
        }
        observe(NSWorkspace.sessionDidResignActiveNotification, on: workspace) { [weak self] _ in
            self?.sessionIsInactive = true
            self?.updatePlayback()
        }
        observe(NSWorkspace.sessionDidBecomeActiveNotification, on: workspace) { [weak self] _ in
            self?.sessionIsInactive = false
            self?.updatePlayback()
        }

        let distributed = DistributedNotificationCenter.default()
        observe(Notification.Name("com.apple.screenIsLocked"), on: distributed) { [weak self] _ in
            self?.screenIsLocked = true
            self?.updatePlayback()
        }
        observe(Notification.Name("com.apple.screenIsUnlocked"), on: distributed) { [weak self] _ in
            self?.screenIsLocked = false
            self?.updatePlayback()
        }
    }

    private func observe(
        _ name: Notification.Name,
        on center: NotificationCenter = .default,
        using block: @escaping (Notification) -> Void
    ) {
        let token = center.addObserver(forName: name, object: nil, queue: .main, using: block)
        observers.append((center, token))
    }

    /// Plays only if the user wants playback and the wallpaper is visible on at least one screen.
    private func updatePlayback() {
        let isSuspended = screensAreAsleep || screenIsLocked || sessionIsInactive
        let isAnyScreenVisible = windows.values.contains { $0.occlusionState.contains(.visible) }
        if isPlaying && !isSuspended && isAnyScreenVisible {
            videoPlayer?.play()
        } else {
            videoPlayer?.pause()
        }
    }

    // MARK: - Playback

    func setVideo(url: URL) {
        // Selecting the current wallpaper again must not restart it from the beginning
        guard url != currentURL else {
            resume()
            return
        }

        videoPlayer?.pause()
        let newPlayer = LoopingVideoPlayer(url: url)
        videoPlayer = newPlayer
        currentURL = url
        isPlaying = true
        for videoView in videoViews.values {
            videoView.player = newPlayer.player
        }
        updatePlayback()
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
        updatePlayback()
    }

    func resume() {
        guard currentURL != nil else { return }
        isPlaying = true
        updatePlayback()
    }

    func stop() {
        isPlaying = false
        currentURL = nil
        videoPlayer?.pause()
        videoPlayer = nil
        for videoView in videoViews.values {
            videoView.player = nil
        }
    }

    deinit {
        for (center, token) in observers {
            center.removeObserver(token)
        }
    }
}
