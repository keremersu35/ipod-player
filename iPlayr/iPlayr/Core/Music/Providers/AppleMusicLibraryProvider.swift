import Foundation
import MusicKit

actor AppleMusicLibraryProvider: LibraryProvider {
    private var songCache: [Song]?
    private var songTask: Task<[Song], Error>?

    func albums() async throws -> [LibraryItem] {
        var request = MusicLibraryRequest<Album>()
        request.sort(by: \.title, ascending: true)
        return try await Self.drain(request.response().items).map(Self.item)
    }

    func playlists() async throws -> [LibraryItem] {
        let request = MusicLibraryRequest<Playlist>()
        return try await Self.drain(request.response().items).map(Self.item)
    }

    func artists() async throws -> [LibraryItem] {
        var request = MusicLibraryRequest<Artist>()
        request.sort(by: \.name, ascending: true)
        return try await Self.drain(request.response().items).map(Self.item)
    }

    func genres() async throws -> [LibraryItem] {
        var request = MusicLibraryRequest<Genre>()
        request.sort(by: \.name, ascending: true)
        return try await Self.drain(request.response().items).map(Self.item)
    }

    func songs() async throws -> [LibraryItem] {
        try await librarySongs().map(Self.item)
    }

    func composers() async throws -> [LibraryItem] {
        let names = try await librarySongs().compactMap {
            $0.composerName?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return Set(names.filter { !$0.isEmpty })
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .map { LibraryItem(id: $0, title: $0) }
    }

    func albumTracks(id: String) async throws -> [LibraryItem] {
        let album = try await album(id: id)
        return Array(try await album.with(.tracks, preferredSource: .library).tracks ?? []).map(Self.item)
    }

    func playlistTracks(id: String) async throws -> [LibraryItem] {
        var request = MusicLibraryRequest<Playlist>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        guard let playlist = try await request.response().items.first else {
            throw MusicLibraryError.playlistNotFound
        }
        return Array(try await playlist.with(.tracks, preferredSource: .library).tracks ?? []).map(Self.item)
    }

    func artistAlbums(id: String) async throws -> [LibraryItem] {
        var request = MusicLibraryRequest<Artist>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        guard let artist = try await request.response().items.first else {
            throw MusicLibraryError.artistNotFound
        }

        var byRelationship = MusicLibraryRequest<Album>()
        byRelationship.filter(matching: \.artists, contains: artist)
        byRelationship.sort(by: \.title, ascending: true)
        let albums = try await Self.drain(byRelationship.response().items)
        guard albums.isEmpty else { return albums.map(Self.item) }

        var byName = MusicLibraryRequest<Album>()
        byName.filter(matching: \.artistName, equalTo: artist.name)
        byName.sort(by: \.title, ascending: true)
        return try await Self.drain(byName.response().items).map(Self.item)
    }

    func genreArtists(id: String) async throws -> [LibraryItem] {
        var request = MusicLibraryRequest<Genre>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        guard let genre = try await request.response().items.first else {
            throw MusicLibraryError.genreNotFound
        }
        var artists = MusicLibraryRequest<Artist>()
        artists.filter(matching: \.genres, contains: genre)
        artists.sort(by: \.name, ascending: true)
        return try await Self.drain(artists.response().items).map(Self.item)
    }

    func composerSongs(name: String) async throws -> [LibraryItem] {
        try await librarySongs()
            .filter { $0.composerName?.trimmingCharacters(in: .whitespacesAndNewlines) == name }
            .map(Self.item)
    }

    func album(id: String) async throws -> Album {
        var request = MusicLibraryRequest<Album>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        guard let album = try await request.response().items.first else {
            throw MusicLibraryError.albumNotFound
        }
        return album
    }

    func playlist(id: String) async throws -> Playlist {
        var request = MusicLibraryRequest<Playlist>()
        request.filter(matching: \.id, equalTo: MusicItemID(id))
        guard let playlist = try await request.response().items.first else {
            throw MusicLibraryError.playlistNotFound
        }
        return playlist
    }

    func songs(ids: [String]) async throws -> [Song] {
        guard !ids.isEmpty else { return [] }
        var request = MusicLibraryRequest<Song>()
        request.filter(matching: \.id, memberOf: ids.map { MusicItemID($0) })
        let found = try await Self.drain(request.response().items)
        let byID = Dictionary(found.map { ($0.id.rawValue, $0) }, uniquingKeysWith: { first, _ in first })
        return ids.compactMap { byID[$0] }
    }

    func invalidateCache() {
        songCache = nil
        songTask = nil
    }

    private func librarySongs() async throws -> [Song] {
        if let songCache { return songCache }
        if let songTask { return try await songTask.value }
        let task = Task {
            var request = MusicLibraryRequest<Song>()
            request.sort(by: \.title, ascending: true)
            return try await Self.drain(request.response().items)
        }
        songTask = task
        defer { if songTask == task { songTask = nil } }
        let songs = try await task.value
        if songTask == task { songCache = songs }
        return songs
    }

    private static func drain<T: MusicItem>(_ firstBatch: MusicItemCollection<T>) async throws -> [T] {
        try await drainPages(first: firstBatch, elements: { Array($0) }) { batch in
            batch.hasNextBatch ? try await batch.nextBatch() : nil
        }
    }

    private static func item(_ album: Album) -> LibraryItem {
        LibraryItem(id: album.id.rawValue, title: album.title, subtitle: album.artistName,
                    artwork: album.artwork.map(ArtworkRef.appleMusic))
    }

    private static func item(_ playlist: Playlist) -> LibraryItem {
        LibraryItem(id: playlist.id.rawValue, title: playlist.name,
                    artwork: playlist.artwork.map(ArtworkRef.appleMusic))
    }

    private static func item(_ artist: Artist) -> LibraryItem {
        LibraryItem(id: artist.id.rawValue, title: artist.name,
                    artwork: artist.artwork.map(ArtworkRef.appleMusic))
    }

    private static func item(_ genre: Genre) -> LibraryItem {
        LibraryItem(id: genre.id.rawValue, title: genre.name)
    }

    private static func item(_ song: Song) -> LibraryItem {
        LibraryItem(id: song.id.rawValue, title: song.title, subtitle: song.artistName,
                    artwork: song.artwork.map(ArtworkRef.appleMusic))
    }

    private static func item(_ track: Track) -> LibraryItem {
        LibraryItem(id: track.id.rawValue, title: track.title, subtitle: track.artistName,
                    artwork: track.artwork.map(ArtworkRef.appleMusic))
    }
}
