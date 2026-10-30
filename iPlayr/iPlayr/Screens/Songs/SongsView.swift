import SwiftUI

struct SongsView: View {
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(OnTheGoStore.self) private var onTheGo
    @Environment(\.navigate) private var navigate

    var body: some View {
        LibraryListView(
            title: String(localized: "Songs"),
            scopeID: "songs",
            emptyMessage: String(localized: "No songs found\nAdd some music to your library"),
            rowHeight: CollectionMenuItem.rowHeight,
            cached: { libraryStore.songs },
            load: {
                await libraryStore.loadSongsIfNeeded()
                return libraryStore.songs
            },
            onSelect: { _, index in
                navigate(.push(.player(source: .allSongs, trackIndex: index)))
            },
            onHold: { song in
                onTheGo.add(song)
                return String(localized: "Added to On-The-Go")
            },
            indexTitle: { $0.title }
        ) { song, isSelected in
            CollectionMenuItem(item: song, isSelected: isSelected)
        }
    }
}
