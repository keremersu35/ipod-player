import SwiftUI

struct GenresView: View {
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(\.navigate) private var navigate

    var body: some View {
        LibraryListView(
            title: String(localized: "Genres"),
            scopeID: "genres",
            emptyMessage: String(localized: "No genres found\nAdd some music to your library"),
            cached: { libraryStore.genres },
            load: {
                await libraryStore.loadGenresIfNeeded()
                return libraryStore.genres
            },
            onSelect: { genre, _ in
                navigate(.push(.artists(genre: CollectionInfoModel(id: genre.id, title: genre.title))))
            }
        ) { genre, isSelected in
            MenuItemView(menu: Menu(name: genre.title, next: isSelected), isSelected: isSelected)
        }
    }
}
