import SwiftUI

struct ComposerSongsView: View {
    let composer: String
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(\.navigate) private var navigate

    var body: some View {
        LibraryListView(
            title: composer,
            scopeID: "composerSongs",
            emptyMessage: String(localized: "No songs found for this composer"),
            cached: { libraryStore.cachedComposerSongs(name: composer) },
            load: { await libraryStore.composerSongs(name: composer) },
            onSelect: { _, index in
                navigate(.push(.player(source: .composer(name: composer), trackIndex: index)))
            }
        ) { song, isSelected in
            CollectionMenuItem(item: song, isSelected: isSelected)
        }
    }
}
