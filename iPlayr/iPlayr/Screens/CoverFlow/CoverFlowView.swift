import SwiftUI

struct CoverFlowView: View {
    @Environment(iPlayrButtonController.self) var iPlayrController
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(\.navigate) private var navigate
    @State private var scrollAnimator = CoverFlowScrollAnimator()
    @State private var carouselScope = FocusScope(id: "coverFlow")
    @State private var songListScope = FocusScope(id: "coverFlowSongList")

    private var albums: [LibraryItem] { libraryStore.albums ?? [] }
    private var selectedIndex: Int { carouselScope.selection }
    @State private var selectedTrackIndex = 0
    @State private var viewState: ViewState = .loading
    @State private var isPlayerView = false
    @State private var isSongList = false
    @State private var playerViewId = UUID()

    private let itemStep = CoverFlowMetrics.itemStep

    var body: some View {
        VStack(spacing: 0) {
            StatusBar(title: isPlayerView ? String(localized: "Now Playing") : String(localized: "Cover Flow"))

            ZStack {
                if viewState == .content {
                    contentView
                }

                if isPlayerView, albums.indices.contains(selectedIndex) {
                    PlayerView(
                        source: .album(id: albums[selectedIndex].id),
                        trackIndex: selectedTrackIndex,
                        isFromCoverFlow: true,
                        initialArtwork: albums[selectedIndex].artwork,
                        onDismissFromCoverFlow: handleMenuAction
                    )
                    .id(playerViewId)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .zIndex(2)
                }

                StateView(state: viewState)
            }
            .padding(.vertical, 16)
            .frame(maxHeight: .infinity)
            .background(Color.white)
        }
        .taskAfterNavigation { await loadAlbums() }
        .onAppear(perform: setup)
        .onChange(of: albums.count) { _, count in
            guard viewState == .content else { return }
            carouselScope.itemCount = count
        }
        .onChange(of: carouselScope.selection) { _, newIndex in
            scrollAnimator.settle(at: -CGFloat(newIndex) * itemStep)
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if !isPlayerView {
            VStack(spacing: 0) {
                Spacer().frame(height: 8)
                CoverFlowCarousel(
                    albums: albums,
                    selectedIndex: selectedIndex,
                    scrollAnimator: scrollAnimator,
                    isSongList: $isSongList,
                    songListScope: songListScope,
                    onDragEnd: navigateTo
                )

                Spacer().frame(height: 35)
            }
            .zIndex(isSongList ? 2 : 0)

            if !albums.isEmpty {
                albumInfo
            }
        }
    }

    private var albumInfo: some View {
        let album = albums.indices.contains(selectedIndex) ? albums[selectedIndex] : nil
        return VStack(spacing: 2) {
            Spacer()
            Text(album?.title ?? "")
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.black)
                .lineLimit(1)
                .id("title-\(selectedIndex)")
                .transition(.opacity)
            Text(album?.subtitle ?? "")
                .font(.system(size: 16, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.black)
                .lineLimit(1)
                .id("artist-\(selectedIndex)")
                .transition(.opacity)
        }
        .padding(.horizontal, 16)
        .zIndex(1)
    }

    private func navigateTo(_ index: Int) {
        if carouselScope.selection == index {
            scrollAnimator.settle(at: -CGFloat(index) * itemStep)
        } else {
            carouselScope.select(index)
        }
    }

    private func loadAlbums() async {
        viewState = .loading
        await libraryStore.loadAlbumsIfNeeded()

        guard let savedAlbums = libraryStore.albums else {
            viewState = .error(message: libraryStore.errorMessage ?? String(localized: "An error occurred\nPlease try again"))
            return
        }

        if savedAlbums.isEmpty {
            viewState = .empty(message: String(localized: "No albums found\nAdd some albums to your library"))
        } else {
            let initialIndex = max(0, savedAlbums.count / 2)
            carouselScope.configure(itemCount: savedAlbums.count, selection: initialIndex)
            scrollAnimator.jumpTo(-CGFloat(initialIndex) * itemStep)
            viewState = .content
        }
    }

    private func setup() {
        carouselScope.onAction = { handleButtonAction($0) }
        iPlayrController.activate(carouselScope)
    }

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu:   handleMenuAction()
        case .select: handleSelectAction()
        default: break
        }
    }

    private func handleMenuAction() {
        if isPlayerView {
            isPlayerView = false
            isSongList = false
            selectedTrackIndex = 0
            configureController()
        } else if isSongList {
            isSongList = false
            configureController()
        } else {
            navigate(.pop)
        }
    }

    private func handleSelectAction() {
        if isSongList && iPlayrController.activeScope === songListScope {
            let trackIndex = songListScope.selection
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                playerViewId = UUID()
                selectedTrackIndex = trackIndex
                isPlayerView = true
            }
        } else if !isSongList && !isPlayerView {
            isSongList = true
            songListScope.onAction = { handleButtonAction($0) }
            iPlayrController.activate(songListScope)
        }
    }

    private func configureController() {
        carouselScope.onAction = { handleButtonAction($0) }
        iPlayrController.activate(carouselScope)
    }
}

private struct CoverFlowCarousel: View {
    let albums: [LibraryItem]
    let selectedIndex: Int
    let scrollAnimator: CoverFlowScrollAnimator
    @Binding var isSongList: Bool
    let songListScope: FocusScope
    let onDragEnd: (Int) -> Void

    private let itemWidth = CoverFlowMetrics.coverSize
    private let itemStep = CoverFlowMetrics.itemStep
    private let tilt = CoverFlowMetrics.tilt
    private let cfSpacing = CoverFlowMetrics.spacing

    private var visibleIndices: ClosedRange<Int>? {
        guard !albums.isEmpty else { return nil }
        let lower = max(0, selectedIndex - CoverFlowMetrics.windowRadius)
        let upper = min(albums.count - 1, selectedIndex + CoverFlowMetrics.windowRadius)
        guard lower <= upper else { return nil }
        return lower...upper
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let visibleIndices {
                    ForEach(visibleIndices, id: \.self) { index in
                        let offset = relativeOffset(for: index)
                        AlbumCover(album: albums[index], isSelected: index == selectedIndex, isSongList: $isSongList, songListScope: songListScope)
                            .frame(width: itemWidth, height: itemWidth)
                            .rotation3DEffect(.degrees(rotation(offset)), axis: (x: 0, y: 1, z: 0), perspective: 0.3)
                            .scaleEffect(scale(offset))
                            .offset(x: xOffset(offset))
                            .zIndex(isSongList && index == selectedIndex ? 1000 : zIndex(offset))
                    }
                }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
        .contentShape(Rectangle())
        .simultaneousGesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { scrollAnimator.dragOffset = $0.translation.width }
            .onEnded { value in
                let projected = scrollAnimator.scrollOffset + value.translation.width + value.predictedEndTranslation.width / 2
                let index = Int(max(0, min(CGFloat(albums.count - 1), round(-projected / itemStep))))
                onDragEnd(index)
            }
    }

    private func relativeOffset(for index: Int) -> CGFloat {
        (CGFloat(index) * itemStep + scrollAnimator.visualOffset) / itemStep
    }

    private func rotation(_ offset: CGFloat) -> Double {
        -Double(max(-1, min(1, offset))) * 90 * Double(tilt)
    }

    private func xOffset(_ offset: CGFloat) -> CGFloat {
        let clamp = max(-1, min(1, offset))
        return (clamp * 0.5 * tilt + offset * cfSpacing) * itemWidth
    }

    private func scale(_ offset: CGFloat) -> CGFloat {
        max(1 - abs(max(-1, min(1, offset))) * 0.15, 0.85)
    }

    private func zIndex(_ offset: CGFloat) -> Double {
        (2 - abs(Double(offset))) * 10
    }
}
