import AppKit
import AVFoundation

final class WallpaperVideoView: NSView {
    private var player: AVQueuePlayer?
    private var playerLayer: AVPlayerLayer?
    private var looper: AVPlayerLooper?  // Must retain — deallocation stops looping

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func play(url: URL) {
        // Clean up previous playback
        stop()

        let asset = AVURLAsset(url: url)
        let templateItem = AVPlayerItem(asset: asset)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true

        let layer = AVPlayerLayer(player: queuePlayer)
        layer.frame = bounds
        layer.videoGravity = .resizeAspectFill
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        self.layer?.sublayers?.removeAll()
        self.layer?.addSublayer(layer)

        let playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: templateItem)

        self.player = queuePlayer
        self.playerLayer = layer
        self.looper = playerLooper

        queuePlayer.play()
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func stop() {
        player?.pause()
        looper = nil
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
    }

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }
}
