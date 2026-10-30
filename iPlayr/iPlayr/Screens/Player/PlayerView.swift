import SwiftUI

struct PlayerView: View {
    let source: PlaybackSource?
    let trackIndex: Int
    let isFromCoverFlow: Bool
    var initialArtwork: ArtworkRef?
    var onDismissFromCoverFlow: (() -> Void)? = nil
    @State private var activeArtwork: ArtworkRef?
    @Environment(\.navigate) private var navigate
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(PlaybackController.self) private var playerManager
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(OnTheGoStore.self) private var onTheGo
    @Environment(RatingStore.self) private var ratings
    @State private var scope = FocusScope(id: "player", handledTransportActions: [.playPause, .forwardEndAlt, .backwardEndAlt])
    @State private var currentDegree: Double = 80
    @State private var currentOpacity: Double = 0
    @State private var isScaleAnimation: Bool = true
    @State private var seekTask: Task<Void, Never>?
    @State private var playbackErrorMessage: String?
    @State private var mode: NowPlayingMode = .progress
    @State private var volumeLevel: Float?
    @State private var contextSelection: Int?
    @State private var idleClock = InactivityTimer()

    private static let artworkSize: CGFloat = 150
    private static let idleClockDelay: Duration = .seconds(60)
    private static let albumShuffleLimit = 200

    private enum ContextOption: Int, CaseIterable {
        case addToOnTheGo, browseAlbum, browseArtist, cancel

        var title: String {
            switch self {
            case .addToOnTheGo: return String(localized: "Add to On-The-Go")
            case .browseAlbum: return String(localized: "Browse Album")
            case .browseArtist: return String(localized: "Browse Artist")
            case .cancel: return String(localized: "Cancel")
            }
        }
    }

    private let initialRotation: Double = 80
    private let finalRotation: Double = 5
    private let flipDuration: Double = 0.6
    private let fadeDelay: Double = 0.3
    private let fadeDuration: Double = 0.4

    var body: some View {
        ZStack {
            playerContent
            if let playbackErrorMessage {
                errorOverlay(playbackErrorMessage)
            }
        }
        .background(Color.white)
        .frame(maxHeight: .infinity)
        .overlay {
            if idleClock.hasElapsed && !isFromCoverFlow {
                VStack(spacing: 0) {
                    StatusBar(title: String(localized: "Now Playing"))
                    IdleClockView()
                }
                .transition(.opacity)
            }
        }
        .overlay {
            if let contextSelection, let track = playerManager.currentTrack {
                ContextMenuOverlay(title: track.title, options: ContextOption.allCases.map(\.title), selection: contextSelection)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            }
        }
        .onAppear {
            if let artwork = initialArtwork {
                activeArtwork = artwork
            } else {
                activeArtwork = playerManager.currentTrack?.artwork
            }
            if !isFromCoverFlow {
                currentDegree = finalRotation
                currentOpacity = 1
                isScaleAnimation = false
            }
            setupButtonListener()
        }
        .taskAfterNavigation { await startPlayback() }
        .task(id: volumeLevel) {
            guard volumeLevel != nil else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.18)) { volumeLevel = nil }
        }
        .onDisappear {
            stopSeeking()
            idleClock.stop()
            iPlayrController.observeActivity(idleClock.id, handler: nil)
        }
    }

    private func startPlayback() async {
        guard let source else { return }
        do {
            try await playerManager.play(source: source, items: await items(for: source), fromIndex: startIndex(for: source))
        } catch {
            playbackErrorMessage = error.localizedDescription
        }
    }

    private func items(for source: PlaybackSource) async -> [LibraryItem] {
        switch source {
        case .album, .playlist:
            return []
        case .composer(let name):
            return await libraryStore.composerSongs(name: name) ?? []
        case .allSongs:
            await libraryStore.loadSongsIfNeeded()
            return libraryStore.songs ?? []
        case .shuffleAll:
            if playerManager.shuffleMode == .albums {
                return await albumShuffledItems()
            }
            await libraryStore.loadSongsIfNeeded()
            return libraryStore.songs?.shuffled() ?? []
        case .onTheGo:
            return onTheGo.items
        }
    }

    private func albumShuffledItems() async -> [LibraryItem] {
        await libraryStore.loadAlbumsIfNeeded()
        var items: [LibraryItem] = []
        for album in (libraryStore.albums ?? []).shuffled() {
            items += await libraryStore.albumTracks(id: album.id) ?? []
            if items.count >= Self.albumShuffleLimit { break }
        }
        return items
    }

    private func startIndex(for source: PlaybackSource) -> Int {
        source == .shuffleAll ? 0 : trackIndex
    }

    private func errorOverlay(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: ImageNames.System.xCircle)
                .font(.system(size: 40))
                .foregroundColor(.red.opacity(0.6))
            Text(message)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .minimumScaleFactor(0.4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private var playerContent: some View {
        VStack(spacing: 0) {
            if !isFromCoverFlow {
                StatusBar(title: String(localized: "Now Playing"))
            }
            VStack(spacing: 0) {
                HStack(spacing: 24) {
                    ZStack {
                        if let image = activeArtwork {
                            ArtworkView(artwork: image, width: Self.artworkSize)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: Self.artworkSize, height: Self.artworkSize)
                                .reflection()
                                .rotation3DEffect(.degrees(currentDegree), axis: (x: 0, y: 1, z: 0))
                                .scaleEffect(isScaleAnimation ? 1.2 : 1)
                                .onAppear {
                                    guard isFromCoverFlow else { return }
                                    isScaleAnimation = true
                                    currentDegree = initialRotation
                                    currentOpacity = 0
                                    DispatchQueue.main.async {
                                        withAnimation(.snappy(duration: flipDuration)) {
                                            isScaleAnimation = false
                                            currentDegree = finalRotation
                                        }
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + fadeDelay) {
                                        withAnimation(.easeInOut(duration: fadeDuration)) {
                                            currentOpacity = 1
                                        }
                                    }
                                }
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: Self.artworkSize, height: Self.artworkSize)
                    .onChange(of: playerManager.currentTrack) { _, newValue in
                        if let newArtwork = newValue?.artwork {
                            activeArtwork = newArtwork
                        }
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text(playerManager.currentTrack?.title ?? "")
                            .font(.iPod(iPodTypeScale.nowPlayingTitle))
                            .foregroundColor(.black)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .id(playerManager.currentTrack?.title ?? "")
                        Text(playerManager.currentTrack?.artistName ?? "")
                            .font(.iPod(iPodTypeScale.nowPlayingDetail))
                            .foregroundColor(.nowPlayingDetail)
                            .lineLimit(1)
                            .id(playerManager.currentTrack?.artistName ?? "")
                        Text(playerManager.currentTrack?.albumTitle ?? "")
                            .font(.iPod(iPodTypeScale.nowPlayingDetail))
                            .foregroundColor(.nowPlayingDetail)
                            .lineLimit(1)
                            .id(playerManager.currentTrack?.albumTitle ?? "")
                        let rating = ratings.rating(for: playerManager.currentTrack?.id)
                        if rating > 0 {
                            Text(String(repeating: "★", count: rating))
                                .font(.iPod(iPodTypeScale.nowPlayingPosition))
                                .foregroundColor(.nowPlayingDetail)
                                .padding(.top, 2)
                        }
                        if let queuePosition = playerManager.queuePosition {
                            Text(queuePosition)
                                .font(.iPod(iPodTypeScale.nowPlayingPosition))
                                .foregroundColor(.nowPlayingDetail)
                                .padding(.top, 2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(currentOpacity)
                }
                .frame(height: Self.artworkSize)
                Spacer(minLength: 8)
                modeControls
                    .environment(playerManager)
                    .opacity(currentOpacity)
                    .padding(.horizontal, -4)
            }
            .padding(.horizontal, 24)
            .padding(.top, isFromCoverFlow ? 8 : 24)
            .padding(.bottom, isFromCoverFlow ? 8 : 26)
        }
        .overlay(alignment: .topTrailing) {
            playbackModeIcons
                .padding(.horizontal, 8)
                .padding(.top, isFromCoverFlow ? 4 : StatusBar.height + 4)
                .opacity(currentOpacity)
        }
    }

    private var playbackModeIcons: some View {
        HStack(spacing: 6) {
            if playerManager.shuffleMode != .off {
                Image(systemName: ImageNames.System.shuffle)
            }
            switch playerManager.repeatMode {
            case .all:
                Image(systemName: ImageNames.System.repeatAll)
            case .one:
                Image(systemName: ImageNames.System.repeatOne)
            default:
                EmptyView()
            }
        }
        .font(.system(size: 13, weight: .heavy))
        .foregroundColor(.black)
        .frame(height: 19)
    }

    private var modeControls: some View {
        Group {
            if let volumeLevel {
                VolumeBarView(level: volumeLevel)
            } else {
                switch mode {
                case .progress:
                    SongProgressView()
                case .scrubber:
                    ScrubberView()
                case .rating:
                    RatingBarView(rating: ratings.rating(for: playerManager.currentTrack?.id))
                case .shuffle:
                    ShuffleBarView(mode: playerManager.shuffleMode)
                }
            }
        }
        .frame(height: NowPlayingBarMetrics.height)
        .transition(.opacity)
    }

    private func handleScroll(_ delta: Int) -> Bool {
        if dismissIdleClock() { return true }
        if let contextSelection {
            let target = min(max(contextSelection + delta, 0), ContextOption.allCases.count - 1)
            guard target != contextSelection else { return false }
            self.contextSelection = target
            return true
        }
        switch mode {
        case .rating:
            guard let trackID = playerManager.currentTrack?.id else { return false }
            let current = ratings.rating(for: trackID)
            let target = min(max(current + delta, 0), RatingStore.maxRating)
            guard target != current else { return false }
            ratings.setRating(target, for: trackID)
            return true
        case .shuffle:
            let all = ShuffleMode.allCases
            let index = all.firstIndex(of: playerManager.shuffleMode) ?? 0
            let target = min(max(index + delta, 0), all.count - 1)
            guard target != index else { return false }
            playerManager.setShuffleMode(all[target])
            return true
        case .progress:
            guard let newLevel = SystemVolume.adjust(by: Float(delta) * 0.0625) else { return false }
            withAnimation(.easeInOut(duration: 0.18)) { volumeLevel = newLevel }
            return true
        case .scrubber:
            guard let duration = playerManager.currentTrack?.duration, duration > 0 else { return false }
            let step = max(1, duration / 60)
            playerManager.seek(to: playerManager.currentPlaybackTime + Double(delta) * step)
            return true
        }
    }

    private func setupButtonListener() {
        scope.onScroll = { handleScroll($0) }
        scope.onAction = { action in
            if dismissIdleClock() { return }
            if contextSelection != nil {
                handleContextAction(action)
                return
            }
            switch action {
            case .selectLongPress:
                guard playerManager.currentTrack != nil else { return }
                withAnimation(.easeOut(duration: 0.15)) { contextSelection = ContextOption.addToOnTheGo.rawValue }
            case .menu:
                if isFromCoverFlow {
                    onDismissFromCoverFlow?()
                } else {
                    navigate(.pop)
                }
            case .select:
                withAnimation(.easeInOut(duration: 0.18)) {
                    volumeLevel = nil
                    mode = mode.next
                }
            case .forwardEndAlt:
                Task { try? await playerManager.skipToNextTrack() }
            case .backwardEndAlt:
                Task { try? await playerManager.skipToPreviousTrack() }
            case .playPause:
                Task {
                    try? await playerManager.togglePlayPause()
                }
            case .forwardLongPress:
                startSeeking(forward: true)
            case .forwardLongPressEnd:
                stopSeeking()
            case .backwardLongPress:
                startSeeking(forward: false)
            case .backwardLongPressEnd:
                stopSeeking()
            }
        }
        iPlayrController.activate(scope)
        let restart = { restartIdleClock() }
        iPlayrController.observeActivity(idleClock.id, handler: restart)
        restart()
    }

    private func dismissIdleClock() -> Bool {
        guard idleClock.hasElapsed else { return false }
        restartIdleClock()
        return true
    }

    private func restartIdleClock() {
        let playerManager = playerManager
        idleClock.restart(
            after: Self.idleClockDelay,
            wakeAnimation: .easeOut(duration: 0.2),
            elapseAnimation: .easeInOut(duration: 0.4),
            shouldElapse: { playerManager.isPlaying }
        )
    }

    private func handleContextAction(_ action: ButtonAction) {
        switch action {
        case .menu:
            closeContextMenu()
        case .select:
            guard let contextSelection, let option = ContextOption(rawValue: contextSelection) else { return }
            closeContextMenu()
            perform(option)
        default:
            break
        }
    }

    private func closeContextMenu() {
        withAnimation(.easeOut(duration: 0.15)) { contextSelection = nil }
    }

    private func perform(_ option: ContextOption) {
        guard let track = playerManager.currentTrack else { return }
        switch option {
        case .addToOnTheGo:
            onTheGo.add(LibraryItem(id: track.id, title: track.title, subtitle: track.artistName))
        case .browseAlbum:
            Task {
                await libraryStore.loadAlbumsIfNeeded()
                let albums = libraryStore.albums ?? []
                let match = albums.first { $0.title == track.albumTitle && $0.subtitle == track.artistName }
                    ?? albums.first { $0.title == track.albumTitle }
                guard let match else { return }
                navigate(.push(.albumTracks(album: CollectionInfoModel(id: match.id, title: match.title))))
            }
        case .browseArtist:
            Task {
                await libraryStore.loadArtistsIfNeeded()
                guard let match = libraryStore.artists?.first(where: { $0.title == track.artistName }) else { return }
                navigate(.push(.artistAlbums(artist: CollectionInfoModel(id: match.id, title: match.title))))
            }
        case .cancel:
            break
        }
    }

    private func startSeeking(forward: Bool) {
        guard seekTask == nil else { return }
        seekTask = Task {
            let start = ContinuousClock.now
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard !Task.isCancelled else { return }
                let speed = Self.seekSpeed(after: ContinuousClock.now - start)
                if forward {
                    playerManager.seekForward(seconds: speed)
                } else {
                    playerManager.seekBackward(seconds: speed)
                }
            }
        }
    }

    private func stopSeeking() {
        seekTask?.cancel()
        seekTask = nil
    }

    private static func seekSpeed(after elapsed: Duration) -> Double {
        switch elapsed {
        case ..<Duration.seconds(1): return 1
        case ..<Duration.seconds(3): return 2
        case ..<Duration.seconds(5): return 5
        case ..<Duration.seconds(10): return 10
        default: return 20
        }
    }
}


struct SongProgressView: View {
    @Environment(PlaybackController.self) private var playerManager

    private var duration: TimeInterval { playerManager.currentTrack?.duration ?? 0 }

    private var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, playerManager.currentPlaybackTime / duration)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: playerManager.isPlaying ? 0.25 : 3600)) { _ in
            NowPlayingBar(progress: progress) {
                TimeLabel(seconds: Int(progress * duration))
            } trailing: {
                TimeLabel(seconds: Int(duration - progress * duration), isRemaining: true)
            }
        }
    }
}
