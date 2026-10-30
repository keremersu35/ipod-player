import SwiftUI

struct AlbumTracksView: View {
    let album: CollectionInfoModel
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(OnTheGoStore.self) private var onTheGo
    @Environment(\.navigate) private var navigate

    var body: some View {
        LibraryListView(
            title: album.title,
            scopeID: "albumTracks",
            emptyMessage: String(localized: "No tracks found in this album"),
            cached: { libraryStore.cachedAlbumTracks(id: album.id) },
            load: { await libraryStore.albumTracks(id: album.id) },
            onSelect: { _, index in
                navigate(.push(.player(source: .album(id: album.id), trackIndex: index)))
            },
            onHold: { song in
                onTheGo.add(song)
                return String(localized: "Added to On-The-Go")
            }
        ) { track, isSelected in
            MenuItemView(menu: Menu(name: track.title, next: isSelected), isSelected: isSelected)
        }
    }
}
