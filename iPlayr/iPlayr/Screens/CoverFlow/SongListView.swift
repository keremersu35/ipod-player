import SwiftUI

struct SongListView: View {
    let album: LibraryItem
    let isSelected: Bool
    @Binding var isSongList: Bool
    var scope: FocusScope
    @Environment(MusicLibraryStore.self) private var libraryStore
    @State private var isLoading = true
    @State private var tracks: [LibraryItem] = []
    private var shouldLoad: Bool { isSongList && isSelected }

    var body: some View {
        VStack(spacing: 0) {
            Group {
                albumHeader
                tracksList
            }
            .opacity(isLoading ? 0 : 1)

            if isLoading {
                LoadingView()
            }
        }
        .task(id: shouldLoad) {
            guard shouldLoad else { return }
            await loadTracks()
        }
    }

    private var albumHeader: some View {
        VStack(spacing: 0) {
            albumTitle
            artistName
        }
        .background(Color.songListBackground)
    }

    private var albumTitle: some View {
        Text(album.title)
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .padding(.leading, 8)
            .lineLimit(1)
    }

    private var artistName: some View {
        Text(album.subtitle)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 4)
            .padding(.leading, 8)
            .lineLimit(1)
    }

    private var tracksList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(tracks.enumerated()), id: \.offset) { index, track in
                        MenuItemView(
                            menu: Menu(id: index, name: track.title, next: scope.selection == index),
                            isSelected: scope.selection == index
                        )
                        .id(index)
                    }
                }
                .onChange(of: scope.selection) { _, newIndex in
                    proxy.jump(to: newIndex)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        proxy.jump(to: scope.selection)
                    }
                }
            }
            .padding(.bottom, 26)
        }
    }

    private func loadTracks() async {
        let loaded = await libraryStore.albumTracks(id: album.id) ?? []
        guard !Task.isCancelled else { return }
        tracks = loaded
        scope.configure(itemCount: loaded.count)
        isLoading = false
    }
}

