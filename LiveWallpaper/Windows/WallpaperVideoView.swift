import AppKit
import AVFoundation

/// Muted, endlessly looping playback of one video file.
final class LoopingVideoPlayer {
    let player = AVQueuePlayer()
    private let looper: AVPlayerLooper  // Must retain — deallocation stops looping

    init(url: URL) {
        player.isMuted = true
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(asset: AVURLAsset(url: url)))
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }
}

/// Displays a player's frames. Several views can share one player, so a video
/// shown on multiple screens is decoded only once.
final class WallpaperVideoView: NSView {
    private var playerLayer: AVPlayerLayer?
    private var readyObservation: NSKeyValueObservation?

    /// Each new player gets its own layer. The previous layer stays visible until the new
    /// video's first frame is ready, so switching never flashes the desktop picture.
    var player: AVPlayer? {
        get { playerLayer?.player }
        set { show(newValue) }
    }

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func show(_ newPlayer: AVPlayer?) {
        guard newPlayer !== playerLayer?.player else { return }

        let previousLayer = playerLayer
        readyObservation = nil
        // Drop layers still waiting to be replaced from an earlier switch
        layer?.sublayers?
            .filter { $0 !== previousLayer }
            .forEach { $0.removeFromSuperlayer() }

        guard let newPlayer else {
            previousLayer?.removeFromSuperlayer()
            playerLayer = nil
            return
        }

        let newLayer = AVPlayerLayer(player: newPlayer)
        newLayer.frame = bounds
        newLayer.videoGravity = .resizeAspectFill
        newLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer?.addSublayer(newLayer)
        playerLayer = newLayer

        readyObservation = newLayer.observe(\.isReadyForDisplay, options: [.initial, .new]) { [weak previousLayer] layer, _ in
            guard layer.isReadyForDisplay else { return }
            DispatchQueue.main.async {
                previousLayer?.removeFromSuperlayer()
            }
        }
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        // Resize without the implicit layer animation (visible in the small list previews)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.sublayers?.forEach { $0.frame = bounds }
        CATransaction.commit()
    }
}
