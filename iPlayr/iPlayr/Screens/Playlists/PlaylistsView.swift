import SwiftUI

struct PlaylistsView: View {
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(OnTheGoStore.self) private var onTheGo
    @Environment(\.navigate) private var navigate

    var body: some View {
        LibraryListView(
            title: String(localized: "Playlists"),
            scopeID: "playlists",
            emptyMessage: String(localized: "No playlists found\nCreate some playlists to get started"),
            rowHeight: CollectionMenuItem.rowHeight,
            cached: { libraryStore.playlists.map { [onTheGo.playlistItem] + $0 } },
            load: {
                await libraryStore.loadPlaylistsIfNeeded()
                return [onTheGo.playlistItem] + (libraryStore.playlists ?? [])
            },
            onSelect: { playlist, _ in
                guard playlist.id != OnTheGoStore.playlistID else {
                    navigate(.push(.onTheGo))
                    return
                }
                navigate(.push(.playlistTracks(playlist: CollectionInfoModel(id: playlist.id, title: playlist.title))))
            }
        ) { playlist, isSelected in
            CollectionMenuItem(item: playlist, isSelected: isSelected)
        }
    }
}
