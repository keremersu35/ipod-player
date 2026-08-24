import SwiftUI

struct PlaylistsView: View {
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(\.navigate) private var navigate

    var body: some View {
        LibraryListView(
            title: String(localized: "Playlists"),
            scopeID: "playlists",
            emptyMessage: String(localized: "No playlists found\nCreate some playlists to get started"),
            cached: { libraryStore.playlists },
            load: {
                await libraryStore.loadPlaylistsIfNeeded()
                return libraryStore.playlists
            },
            onSelect: { playlist, _ in
                navigate(.push(.playlistTracks(playlist: CollectionInfoModel(id: playlist.id, title: playlist.title))))
            }
        ) { playlist, isSelected in
            CollectionMenuItem(item: playlist, isSelected: isSelected)
        }
    }
}
