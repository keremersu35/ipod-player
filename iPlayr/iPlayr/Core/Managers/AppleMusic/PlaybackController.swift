import Foundation
import Observation

@MainActor
@Observable
final class PlaybackController {
    private(set) var currentTrack: NowPlayingTrack?
    private(set) var isPlaying = false
    private(set) var isPaused = false
    private(set) var queuePosition: String?
    private(set) var shuffleMode: ShuffleMode = .off
    private(set) var repeatMode: RepeatMode = .off

    var currentPlaybackTime: TimeInterval { provider.position }

    @ObservationIgnored private var provider: any PlaybackProvider

    init(provider: any PlaybackProvider) {
        self.provider = provider
        observe()
    }

    func use(_ provider: any PlaybackProvider) {
        self.provider.stop()
        self.provider.onStateChange = nil
        self.provider = provider
        observe()
        syncFromProvider()
    }

    private func observe() {
        provider.onStateChange = { [weak self] in
            self?.syncFromProvider()
        }
    }

    private func syncFromProvider() {
        currentTrack = provider.currentTrack
        isPlaying = provider.isPlaying
        isPaused = provider.isPaused
        queuePosition = provider.queuePosition
        shuffleMode = provider.shuffleMode
        repeatMode = provider.repeatMode
    }

    func play(source: PlaybackSource, items: [LibraryItem], fromIndex: Int) async throws {
        try await provider.play(source: source, items: items, fromIndex: fromIndex)
    }

    func togglePlayPause() async throws { try await provider.togglePlayPause() }
    func skipToNextTrack() async throws { try await provider.skipToNext() }
    func skipToPreviousTrack() async throws { try await provider.skipToPrevious() }
    func stop() { provider.stop() }
    func seek(to time: TimeInterval) { provider.seek(to: time) }
    func seekForward(seconds: Double = 5.0) { provider.seekBy(seconds) }
    func seekBackward(seconds: Double = 5.0) { provider.seekBy(-seconds) }
    func setShuffleMode(_ mode: ShuffleMode) { provider.setShuffleMode(mode) }
    func setRepeatMode(_ mode: RepeatMode) { provider.setRepeatMode(mode) }
}
