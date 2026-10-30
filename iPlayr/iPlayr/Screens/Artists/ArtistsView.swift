import SwiftUI

struct ArtistsView: View {
    let genre: CollectionInfoModel?
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(\.navigate) private var navigate

    var body: some View {
        LibraryListView(
            title: genre?.title ?? String(localized: "Artists"),
            scopeID: genre.map { "genreArtists-\($0.id)" } ?? "artists",
            emptyMessage: String(localized: "No artists found\nAdd some music to your library"),
            cached: cachedArtists,
            load: loadArtists,
            onSelect: { artist, _ in
                navigate(.push(.artistAlbums(artist: CollectionInfoModel(id: artist.id, title: artist.title))))
            },
            indexTitle: { $0.title }
        ) { artist, isSelected in
            MenuItemView(menu: Menu(name: artist.title, next: isSelected), isSelected: isSelected)
        }
    }

    private func cachedArtists() -> [LibraryItem]? {
        guard let genre else { return libraryStore.artists }
        return libraryStore.cachedGenreArtists(id: genre.id)
    }

    private func loadArtists() async -> [LibraryItem]? {
        guard let genre else {
            await libraryStore.loadArtistsIfNeeded()
            return libraryStore.artists
        }
        return await libraryStore.genreArtists(id: genre.id)
    }
}
