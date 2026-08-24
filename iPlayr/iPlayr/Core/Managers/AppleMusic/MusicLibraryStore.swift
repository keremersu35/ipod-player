import Foundation
import Observation

@MainActor
@Observable
final class MusicLibraryStore {
    private(set) var albums: [LibraryItem]?
    private(set) var playlists: [LibraryItem]?
    private(set) var artists: [LibraryItem]?
    private(set) var genres: [LibraryItem]?
    private(set) var songs: [LibraryItem]?
    private(set) var composers: [LibraryItem]?
    var errorMessage: String?

    @ObservationIgnored private var provider: any LibraryProvider
    @ObservationIgnored private var albumTracksCache: [String: [LibraryItem]] = [:]
    @ObservationIgnored private var playlistTracksCache: [String: [LibraryItem]] = [:]
    @ObservationIgnored private var artistAlbumsCache: [String: [LibraryItem]] = [:]
    @ObservationIgnored private var genreArtistsCache: [String: [LibraryItem]] = [:]
    @ObservationIgnored private var composerSongsCache: [String: [LibraryItem]] = [:]

    init(provider: any LibraryProvider) {
        self.provider = provider
    }

    func use(_ provider: any LibraryProvider) {
        self.provider = provider
        albums = nil
        playlists = nil
        artists = nil
        genres = nil
        songs = nil
        composers = nil
        errorMessage = nil
        albumTracksCache = [:]
        playlistTracksCache = [:]
        artistAlbumsCache = [:]
        genreArtistsCache = [:]
        composerSongsCache = [:]
    }

    func loadAlbumsIfNeeded() async {
        guard albums == nil else { return }
        albums = await fetch { try await provider.albums() }
    }

    func loadPlaylistsIfNeeded() async {
        guard playlists == nil else { return }
        playlists = await fetch { try await provider.playlists() }
    }

    func loadArtistsIfNeeded() async {
        guard artists == nil else { return }
        artists = await fetch { try await provider.artists() }
    }

    func loadGenresIfNeeded() async {
        guard genres == nil else { return }
        genres = await fetch { try await provider.genres() }
    }

    func loadSongsIfNeeded() async {
        guard songs == nil else { return }
        songs = await fetch { try await provider.songs() }
    }

    func loadComposersIfNeeded() async {
        guard composers == nil else { return }
        composers = await fetch { try await provider.composers() }
    }

    func cachedAlbumTracks(id: String) -> [LibraryItem]? { albumTracksCache[id] }
    func cachedPlaylistTracks(id: String) -> [LibraryItem]? { playlistTracksCache[id] }
    func cachedArtistAlbums(id: String) -> [LibraryItem]? { artistAlbumsCache[id] }
    func cachedGenreArtists(id: String) -> [LibraryItem]? { genreArtistsCache[id] }
    func cachedComposerSongs(name: String) -> [LibraryItem]? { composerSongsCache[name] }

    func albumTracks(id: String) async -> [LibraryItem]? {
        await cached(id, in: \.albumTracksCache) { try await provider.albumTracks(id: id) }
    }

    func playlistTracks(id: String) async -> [LibraryItem]? {
        await cached(id, in: \.playlistTracksCache) { try await provider.playlistTracks(id: id) }
    }

    func artistAlbums(id: String) async -> [LibraryItem]? {
        await cached(id, in: \.artistAlbumsCache) { try await provider.artistAlbums(id: id) }
    }

    func genreArtists(id: String) async -> [LibraryItem]? {
        await cached(id, in: \.genreArtistsCache) { try await provider.genreArtists(id: id) }
    }

    func composerSongs(name: String) async -> [LibraryItem]? {
        await cached(name, in: \.composerSongsCache) { try await provider.composerSongs(name: name) }
    }

    private func cached(
        _ key: String,
        in cache: ReferenceWritableKeyPath<MusicLibraryStore, [String: [LibraryItem]]>,
        fetching operation: () async throws -> [LibraryItem]
    ) async -> [LibraryItem]? {
        if let hit = self[keyPath: cache][key] { return hit }
        guard let items = await fetch(operation) else { return nil }
        self[keyPath: cache][key] = items
        return items
    }

    private func fetch(_ operation: () async throws -> [LibraryItem]) async -> [LibraryItem]? {
        do {
            return try await operation()
        } catch {
            errorMessage = String(localized: "Request failed with error: \(error.localizedDescription)")
            return nil
        }
    }
}

enum MusicLibraryError: LocalizedError, Sendable {
    case albumNotFound
    case playlistNotFound
    case artistNotFound
    case genreNotFound

    var errorDescription: String? {
        switch self {
        case .albumNotFound: return "The specified album could not be found."
        case .playlistNotFound: return "The specified playlist could not be found."
        case .artistNotFound: return "The specified artist could not be found."
        case .genreNotFound: return "The specified genre could not be found."
        }
    }
}
