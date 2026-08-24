import SwiftUI

struct AlbumsView: View {
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(\.navigate) private var navigate

    var body: some View {
        LibraryListView(
            title: String(localized: "Albums"),
            scopeID: "albums",
            emptyMessage: String(localized: "No albums found\nAdd some albums to your library"),
            cached: { libraryStore.albums },
            load: {
                await libraryStore.loadAlbumsIfNeeded()
                return libraryStore.albums
            },
            onSelect: { album, _ in
                navigate(.push(.albumTracks(album: CollectionInfoModel(id: album.id, title: album.title))))
            }
        ) { album, isSelected in
            CollectionMenuItem(item: album, isSelected: isSelected)
        }
    }
}
