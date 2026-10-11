import Foundation

enum MusicProviderID: String, CaseIterable, Hashable, Sendable {
    case appleMusic
    case spotify

    var title: String {
        switch self {
        case .appleMusic: return String(localized: "Apple Music")
        case .spotify: return String(localized: "Spotify")
        }
    }
}

struct ProviderCapabilities: OptionSet, Hashable, Sendable {
    let rawValue: Int

    static let genres = ProviderCapabilities(rawValue: 1 << 0)
    static let composers = ProviderCapabilities(rawValue: 1 << 1)
    static let scrubbing = ProviderCapabilities(rawValue: 1 << 2)
    static let repeatOne = ProviderCapabilities(rawValue: 1 << 3)
}

@MainActor
protocol AccountProvider: AnyObject {
    var id: MusicProviderID { get }
    var capabilities: ProviderCapabilities { get }
    var status: AccountStatus { get }

    func refreshStatus() async
    func signIn() async -> Bool
    func signOut()
}

protocol LibraryProvider: Sendable {
    func albums() async throws -> [LibraryItem]
    func playlists() async throws -> [LibraryItem]
    func artists() async throws -> [LibraryItem]
    func songs() async throws -> [LibraryItem]
    func genres() async throws -> [LibraryItem]
    func composers() async throws -> [LibraryItem]

    func albumTracks(id: String) async throws -> [LibraryItem]
    func playlistTracks(id: String) async throws -> [LibraryItem]
    func artistAlbums(id: String) async throws -> [LibraryItem]
    func genreArtists(id: String) async throws -> [LibraryItem]
    func composerSongs(name: String) async throws -> [LibraryItem]

    func invalidateCache() async
}

extension LibraryProvider {
    func genres() async throws -> [LibraryItem] { [] }
    func composers() async throws -> [LibraryItem] { [] }
    func genreArtists(id: String) async throws -> [LibraryItem] { [] }
    func composerSongs(name: String) async throws -> [LibraryItem] { [] }
    func invalidateCache() async {}
}

@MainActor
protocol PlaybackProvider: AnyObject {
    var currentTrack: NowPlayingTrack? { get }
    var isPlaying: Bool { get }
    var isPaused: Bool { get }
    var queuePosition: String? { get }
    var shuffleMode: ShuffleMode { get }
    var repeatMode: RepeatMode { get }
    var position: TimeInterval { get }
    var onStateChange: (@MainActor () -> Void)? { get set }

    func play(source: PlaybackSource, items: [LibraryItem], fromIndex: Int) async throws
    func togglePlayPause() async throws
    func skipToNext() async throws
    func skipToPrevious() async throws
    func stop()
    func seek(to time: TimeInterval)
    func seekBy(_ delta: TimeInterval)
    func setShuffleMode(_ mode: ShuffleMode)
    func setRepeatMode(_ mode: RepeatMode)
}
