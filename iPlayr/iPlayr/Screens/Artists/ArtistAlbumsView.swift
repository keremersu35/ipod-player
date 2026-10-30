import SwiftUI

struct ArtistAlbumsView: View {
    let artist: CollectionInfoModel
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(\.navigate) private var navigate

    var body: some View {
        LibraryListView(
            title: artist.title,
            scopeID: "artistAlbums",
            emptyMessage: String(localized: "No albums found for this artist"),
            rowHeight: CollectionMenuItem.rowHeight,
            cached: { libraryStore.cachedArtistAlbums(id: artist.id) },
            load: { await libraryStore.artistAlbums(id: artist.id) },
            onSelect: { album, _ in
                navigate(.push(.albumTracks(album: CollectionInfoModel(id: album.id, title: album.title))))
            }
        ) { album, isSelected in
            CollectionMenuItem(item: album, isSelected: isSelected)
        }
    }
}
