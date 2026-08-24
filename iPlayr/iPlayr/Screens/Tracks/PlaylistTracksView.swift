import SwiftUI

struct PlaylistTracksView: View {
    let playlist: CollectionInfoModel
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(\.navigate) private var navigate

    var body: some View {
        LibraryListView(
            title: playlist.title,
            scopeID: "playlistTracks",
            emptyMessage: String(localized: "No tracks found in this playlist\nAdd some tracks to get started"),
            cached: { libraryStore.cachedPlaylistTracks(id: playlist.id) },
            load: { await libraryStore.playlistTracks(id: playlist.id) },
            onSelect: { _, index in
                navigate(.push(.player(source: .playlist(id: playlist.id), trackIndex: index)))
            }
        ) { track, isSelected in
            CollectionMenuItem(item: track, isSelected: isSelected)
        }
    }
}
