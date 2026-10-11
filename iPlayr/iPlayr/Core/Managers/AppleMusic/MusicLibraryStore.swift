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
    private(set) var errorMessage: String?

    @ObservationIgnored private var provider: any LibraryProvider
    @ObservationIgnored private var cache: [String: [LibraryItem]] = [:]
    @ObservationIgnored private var inFlight: [String: Task<[LibraryItem]?, Never>] = [:]
    @ObservationIgnored private var generation = 0

    init(provider: any LibraryProvider) {
        self.provider = provider
    }

    func use(_ provider: any LibraryProvider) {
        self.provider = provider
        generation += 1
        albums = nil
        playlists = nil
        artists = nil
        genres = nil
        songs = nil
        composers = nil
        errorMessage = nil
        cache = [:]
        inFlight.values.forEach { $0.cancel() }
        inFlight = [:]
    }

    func loadAlbumsIfNeeded() async { await loadIfNeeded(.albums) }
    func loadPlaylistsIfNeeded() async { await loadIfNeeded(.playlists) }
    func loadArtistsIfNeeded() async { await loadIfNeeded(.artists) }
    func loadGenresIfNeeded() async { await loadIfNeeded(.genres) }
    func loadSongsIfNeeded() async { await loadIfNeeded(.songs) }
    func loadComposersIfNeeded() async { await loadIfNeeded(.composers) }

    func invalidate() async {
        await provider.invalidateCache()
        cache = [:]
        for list in LibraryList.allCases where self[keyPath: list.property] != nil {
            let requestGeneration = generation
            guard let items = await load(list.rawValue, list.fetch), requestGeneration == generation else { continue }
            self[keyPath: list.property] = items
        }
    }

    func cachedAlbumTracks(id: String) -> [LibraryItem]? { cache["albumTracks/\(id)"] }
    func cachedPlaylistTracks(id: String) -> [LibraryItem]? { cache["playlistTracks/\(id)"] }
    func cachedArtistAlbums(id: String) -> [LibraryItem]? { cache["artistAlbums/\(id)"] }
    func cachedGenreArtists(id: String) -> [LibraryItem]? { cache["genreArtists/\(id)"] }
    func cachedComposerSongs(name: String) -> [LibraryItem]? { cache["composerSongs/\(name)"] }

    func albumTracks(id: String) async -> [LibraryItem]? {
        await cached("albumTracks/\(id)") { try await $0.albumTracks(id: id) }
    }

    func playlistTracks(id: String) async -> [LibraryItem]? {
        await cached("playlistTracks/\(id)") { try await $0.playlistTracks(id: id) }
    }

    func artistAlbums(id: String) async -> [LibraryItem]? {
        await cached("artistAlbums/\(id)") { try await $0.artistAlbums(id: id) }
    }

    func genreArtists(id: String) async -> [LibraryItem]? {
        await cached("genreArtists/\(id)") { try await $0.genreArtists(id: id) }
    }

    func composerSongs(name: String) async -> [LibraryItem]? {
        await cached("composerSongs/\(name)") { try await $0.composerSongs(name: name) }
    }

    private func loadIfNeeded(_ list: LibraryList) async {
        guard self[keyPath: list.property] == nil else { return }
        let requestGeneration = generation
        let items = await load(list.rawValue, list.fetch)
        guard requestGeneration == generation, self[keyPath: list.property] == nil else { return }
        self[keyPath: list.property] = items
    }

    private func cached(
        _ key: String,
        operation: @escaping @Sendable (any LibraryProvider) async throws -> [LibraryItem]
    ) async -> [LibraryItem]? {
        if let hit = cache[key] { return hit }
        let requestGeneration = generation
        guard let items = await load(key, operation), requestGeneration == generation else { return nil }
        cache[key] = items
        return items
    }

    private func load(
        _ key: String,
        _ operation: @escaping @Sendable (any LibraryProvider) async throws -> [LibraryItem]
    ) async -> [LibraryItem]? {
        if let running = inFlight[key] { return await running.value }
        let provider = provider
        let task = Task { await fetch { try await operation(provider) } }
        inFlight[key] = task
        let items = await task.value
        if inFlight[key] == task { inFlight[key] = nil }
        return items
    }

    private func fetch(_ operation: () async throws -> [LibraryItem]) async -> [LibraryItem]? {
        errorMessage = nil
        do {
            return try await operation()
        } catch {
            errorMessage = String(localized: "Request failed with error: \(error.localizedDescription)")
            return nil
        }
    }

    private enum LibraryList: String, CaseIterable {
        case albums, playlists, artists, genres, songs, composers

        @MainActor
        var property: ReferenceWritableKeyPath<MusicLibraryStore, [LibraryItem]?> {
            switch self {
            case .albums: \.albums
            case .playlists: \.playlists
            case .artists: \.artists
            case .genres: \.genres
            case .songs: \.songs
            case .composers: \.composers
            }
        }

        var fetch: @Sendable (any LibraryProvider) async throws -> [LibraryItem] {
            switch self {
            case .albums: { try await $0.albums() }
            case .playlists: { try await $0.playlists() }
            case .artists: { try await $0.artists() }
            case .genres: { try await $0.genres() }
            case .songs: { try await $0.songs() }
            case .composers: { try await $0.composers() }
            }
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
        case .albumNotFound: return String(localized: "The specified album could not be found.")
        case .playlistNotFound: return String(localized: "The specified playlist could not be found.")
        case .artistNotFound: return String(localized: "The specified artist could not be found.")
        case .genreNotFound: return String(localized: "The specified genre could not be found.")
        }
    }
}
