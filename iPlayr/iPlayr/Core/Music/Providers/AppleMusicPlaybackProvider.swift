import Foundation
import Combine
import MusicKit

@MainActor
@Observable
final class AppleMusicPlaybackProvider: PlaybackProvider {
    private static let queueLimit = 200
    private static let queueLeadIn = 25

    private(set) var currentTrack: NowPlayingTrack?
    private(set) var isPlaying = false
    private(set) var isPaused = false
    private(set) var isFirst = false
    private(set) var isLast = false
    private(set) var queuePosition: String?
    private(set) var shuffleMode: ShuffleMode = .off
    private(set) var repeatMode: RepeatMode = .off

    var position: TimeInterval { musicPlayer.playbackTime }
    var onStateChange: (@MainActor () -> Void)?

    private let library: AppleMusicLibraryProvider
    private nonisolated(unsafe) let musicPlayer = ApplicationMusicPlayer.shared
    private var cancellables = Set<AnyCancellable>()
    private var isSkipping = false

    init(library: AppleMusicLibraryProvider) {
        self.library = library
        observePlayer()
    }

    func play(source: PlaybackSource, items: [LibraryItem], fromIndex: Int) async throws {
        currentTrack = nil
        switch source {
        case .album(let id):
            let album = try await library.album(id: id)
            let tracks = try await album.with(.tracks, preferredSource: .library).tracks ?? []
            guard tracks.indices.contains(fromIndex) else {
                throw MusicPlayerError.invalidTrackIndex(index: fromIndex, totalTracks: tracks.count)
            }
            musicPlayer.queue = ApplicationMusicPlayer.Queue(album: album, startingAt: tracks[fromIndex])
        case .playlist(let id):
            let playlist = try await library.playlist(id: id)
            let entries = try await playlist.with(.entries).entries ?? []
            guard entries.indices.contains(fromIndex) else {
                throw MusicPlayerError.invalidTrackIndex(index: fromIndex, totalTracks: entries.count)
            }
            musicPlayer.queue = ApplicationMusicPlayer.Queue(playlist: playlist, startingAt: entries[fromIndex])
        case .allSongs, .composer, .shuffleAll:
            try await queueSongs(items, fromIndex: fromIndex)
        }
        musicPlayer.state.shuffleMode = .off
        try await startPlayback()
    }

    /// ApplicationMusicPlayer times out when handed a few hundred entries at once,
    /// so only a window around the chosen song is queued. The lead-in keeps some
    /// history behind the selection so the previous-track button still works.
    private func queueSongs(_ items: [LibraryItem], fromIndex: Int) async throws {
        guard items.indices.contains(fromIndex) else {
            throw MusicPlayerError.invalidTrackIndex(index: fromIndex, totalTracks: items.count)
        }
        let start = max(0, fromIndex - Self.queueLeadIn)
        let end = min(items.count, start + Self.queueLimit)
        let window = Array(items[start..<end])

        let songs = try await library.songs(ids: window.map(\.id))
        guard let startingSong = songs.first(where: { $0.id.rawValue == items[fromIndex].id }) else {
            throw MusicPlayerError.trackNotFound
        }
        musicPlayer.queue = ApplicationMusicPlayer.Queue(for: songs, startingAt: startingSong)
    }

    /// `prepareToPlay()`/`play()` can intermittently fail right after a queue is
    /// assigned (MPMusicPlayerControllerErrorDomain error 6), seemingly because the
    /// player hasn't caught up with the new queue yet. One short-delayed retry clears
    /// it in practice, so we don't surface a scary error for what's usually a
    /// transient timing hiccup.
    private func startPlayback(retriesRemaining: Int = 1) async throws {
        do {
            try await musicPlayer.prepareToPlay()
            try await musicPlayer.play()
        } catch {
            guard retriesRemaining > 0 else { throw error }
            try? await Task.sleep(for: .milliseconds(300))
            try await startPlayback(retriesRemaining: retriesRemaining - 1)
        }
    }

    func togglePlayPause() async throws {
        if isPlaying {
            musicPlayer.pause()
        } else {
            try await musicPlayer.play()
        }
    }

    func skipToNext() async throws {
        guard !isLast, !isSkipping else { return }
        isSkipping = true
        defer { isSkipping = false }
        try await musicPlayer.skipToNextEntry()
        await refresh()
    }

    func skipToPrevious() async throws {
        guard !isFirst, !isSkipping else { return }
        isSkipping = true
        defer { isSkipping = false }
        try await musicPlayer.skipToPreviousEntry()
        await refresh()
    }

    func stop() {
        musicPlayer.stop()
        currentTrack = nil
        queuePosition = nil
    }

    func seek(to time: TimeInterval) {
        guard let duration = currentTrack?.duration else { return }
        musicPlayer.playbackTime = min(max(time, 0), duration)
    }

    func seekBy(_ delta: TimeInterval) {
        let target = musicPlayer.playbackTime + delta
        guard let duration = currentTrack?.duration else {
            musicPlayer.playbackTime = max(target, 0)
            return
        }
        musicPlayer.playbackTime = min(max(target, 0), duration)
    }

    func setShuffleMode(_ mode: ShuffleMode) {
        musicPlayer.state.shuffleMode = mode == .songs ? .songs : .off
        shuffleMode = mode
        onStateChange?()
    }

    func setRepeatMode(_ mode: RepeatMode) {
        switch mode {
        case .off: musicPlayer.state.repeatMode = MusicPlayer.RepeatMode.none
        case .one: musicPlayer.state.repeatMode = .one
        case .all: musicPlayer.state.repeatMode = .all
        }
        repeatMode = mode
        onStateChange?()
    }

    private func observePlayer() {
        Publishers.Merge(musicPlayer.state.objectWillChange, musicPlayer.queue.objectWillChange)
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in await self?.refresh() }
            }
            .store(in: &cancellables)
    }

    private func refresh() async {
        let entries = musicPlayer.queue.entries
        let currentID = musicPlayer.queue.currentEntry?.id
        isLast = entries.last?.id == currentID
        isFirst = entries.first?.id == currentID
        if let index = entries.firstIndex(where: { $0.id == currentID }) {
            queuePosition = String(localized: "\(index + 1) of \(entries.count)")
        } else {
            queuePosition = nil
        }
        shuffleMode = musicPlayer.state.shuffleMode == .songs ? .songs : .off
        switch musicPlayer.state.repeatMode {
        case .one: repeatMode = .one
        case .all: repeatMode = .all
        default: repeatMode = .off
        }
        if case let .song(song) = musicPlayer.queue.currentEntry?.item {
            currentTrack = NowPlayingTrack(
                id: song.id.rawValue,
                title: song.title,
                artistName: song.artistName,
                albumTitle: song.albumTitle,
                duration: song.duration,
                artwork: song.artwork.map(ArtworkRef.appleMusic)
            )
        }
        switch musicPlayer.state.playbackStatus {
        case .playing: (isPlaying, isPaused) = (true, false)
        case .paused: (isPlaying, isPaused) = (false, true)
        case .stopped, .interrupted: (isPlaying, isPaused) = (false, false)
        default: break
        }
        onStateChange?()
    }
}

enum MusicPlayerError: LocalizedError, Sendable {
    case trackNotFound
    case invalidTrackIndex(index: Int, totalTracks: Int)

    var errorDescription: String? {
        switch self {
        case .trackNotFound:
            return "The specified track could not be found."
        case .invalidTrackIndex(let index, let totalTracks):
            return "The track index \(index) is out of range. The item contains \(totalTracks) tracks."
        }
    }
}
