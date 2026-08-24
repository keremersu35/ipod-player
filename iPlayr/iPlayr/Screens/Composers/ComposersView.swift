import SwiftUI

struct ComposersView: View {
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(\.navigate) private var navigate

    var body: some View {
        LibraryListView(
            title: String(localized: "Composers"),
            scopeID: "composers",
            emptyMessage: String(localized: "No composers found\nYour songs have no composer information"),
            cached: { libraryStore.composers },
            load: {
                await libraryStore.loadComposersIfNeeded()
                return libraryStore.composers
            },
            onSelect: { composer, _ in
                navigate(.push(.composerSongs(composer: composer.id)))
            }
        ) { composer, isSelected in
            MenuItemView(menu: Menu(name: composer.title, next: isSelected), isSelected: isSelected)
        }
    }
}
