import SwiftUI

struct SearchView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "search", handledTransportActions: [.forwardEndAlt, .backwardEndAlt])
    @State private var query = ""
    @State private var letterIndex = 0
    @State private var isTyping = true
    @State private var results: [SearchResult] = []

    private static let letters: [Character] = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ")
    private static let resultLimit = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: query.isEmpty ? String(localized: "Search") : String(localized: "Search Results: \(results.count)"))
            ZStack(alignment: .bottom) {
                resultList
                if isTyping {
                    SearchKeyboard(query: query, letters: Self.letters, selectedIndex: letterIndex)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .taskAfterNavigation {
            await libraryStore.loadArtistsIfNeeded()
            await libraryStore.loadAlbumsIfNeeded()
            await libraryStore.loadSongsIfNeeded()
            updateResults()
        }
    }

    private var resultList: some View {
        ScrollIndicatedList(itemCount: results.count, selection: scope.selection, rowHeight: SearchResultRow.height) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(results.indices, id: \.self) { index in
                            SearchResultRow(result: results[index], isSelected: !isTyping && scope.selection == index)
                                .id(index)
                        }
                    }
                }
                .scrollIndicators(.hidden)
                .onChange(of: scope.selection) { _, newIndex in
                    proxy.jump(to: newIndex)
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func setup() {
        scope.configure(itemCount: 0)
        scope.onScroll = { handleScroll($0) }
        scope.onAction = { handleAction($0) }
        iPlayrController.activate(scope)
    }

    private func handleScroll(_ delta: Int) -> Bool {
        if isTyping {
            letterIndex = (letterIndex + delta + Self.letters.count) % Self.letters.count
            return true
        }
        let target = min(max(scope.selection + delta, 0), max(results.count - 1, 0))
        guard target != scope.selection else { return false }
        scope.select(target)
        return true
    }

    private func handleAction(_ action: ButtonAction) {
        switch action {
        case .menu:
            if isTyping {
                if results.isEmpty {
                    navigate(.pop)
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) { isTyping = false }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) { isTyping = true }
            }
        case .select:
            if isTyping {
                query.append(Self.letters[letterIndex])
                updateResults()
            } else {
                open(scope.selection)
            }
        case .backwardEndAlt:
            guard isTyping, !query.isEmpty else { return }
            query.removeLast()
            updateResults()
        default:
            break
        }
    }

    private func updateResults() {
        let needle = query.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else {
            results = []
            scope.configure(itemCount: 0)
            return
        }
        let matches: (LibraryItem) -> Bool = { item in
            item.title.range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
        var found: [SearchResult] = []
        found += (libraryStore.artists ?? []).filter(matches).map { SearchResult(kind: .artist, item: $0) }
        found += (libraryStore.albums ?? []).filter(matches).map { SearchResult(kind: .album, item: $0) }
        found += (libraryStore.songs ?? []).filter(matches).map { SearchResult(kind: .song, item: $0) }
        results = Array(found.prefix(Self.resultLimit))
        scope.itemCount = results.count
        scope.select(0)
    }

    private func open(_ index: Int) {
        guard results.indices.contains(index) else { return }
        let result = results[index]
        switch result.kind {
        case .artist:
            navigate(.push(.artistAlbums(artist: CollectionInfoModel(id: result.item.id, title: result.item.title))))
        case .album:
            navigate(.push(.albumTracks(album: CollectionInfoModel(id: result.item.id, title: result.item.title))))
        case .song:
            guard let songIndex = libraryStore.songs?.firstIndex(where: { $0.id == result.item.id }) else { return }
            navigate(.push(.player(source: .allSongs, trackIndex: songIndex)))
        }
    }
}

struct SearchResult: Hashable {
    enum Kind: Hashable {
        case artist, album, song

        var symbol: String {
            switch self {
            case .artist: return "person.fill"
            case .album: return "square.stack.fill"
            case .song: return ImageNames.System.musicNote
            }
        }
    }

    let kind: Kind
    let item: LibraryItem
}

struct SearchResultRow: View {
    static let height: CGFloat = 40

    let result: SearchResult
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: result.kind.symbol)
                .font(.system(size: 18))
                .foregroundStyle(isSelected ? .white : .gray.opacity(0.6))
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text(result.item.title)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                if !result.item.subtitle.isEmpty {
                    Text(result.item.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(isSelected ? .white.opacity(0.85) : .gray)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(height: Self.height)
        .foregroundStyle(isSelected ? .white : .black)
        .background(SelectionBackground(isSelected: isSelected))
    }
}

struct SearchKeyboard: View {
    let query: String
    let letters: [Character]
    let selectedIndex: Int

    private static let visibleRadius = 6

    var body: some View {
        HStack(spacing: 8) {
            Text(query.isEmpty ? " " : query)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.black)
                .lineLimit(1)
                .truncationMode(.head)
                .padding(.horizontal, 6)
                .frame(width: 84, height: 26, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 4).fill(.white))
            HStack(spacing: 2) {
                ForEach(-Self.visibleRadius...Self.visibleRadius, id: \.self) { offset in
                    let index = (selectedIndex + offset + letters.count) % letters.count
                    let letter = letters[index] == " " ? "␣" : String(letters[index])
                    Text(letter)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 24)
                        .background {
                            if offset == 0 {
                                RoundedRectangle(cornerRadius: 3).fill(Color.menuItemBackground3)
                            }
                        }
                        .opacity(offset == 0 ? 1 : 1 - Double(abs(offset)) * 0.07)
                }
            }
            .frame(maxWidth: .infinity)
            .clipped()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [.black.opacity(0.75), .black.opacity(0.9)], startPoint: .top, endPoint: .bottom))
        )
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.35), lineWidth: 1))
    }
}
