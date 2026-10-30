import SwiftUI
import Combine

struct RightImageView: View {
    var isActive: Bool = true
    @Environment(MusicAccountManager.self) private var authManager
    @Environment(MusicLibraryStore.self) private var libraryStore
    @State private var currentImageIndex = 0
    @State private var images: [ArtworkRef] = []
    @State private var timerCancellable: AnyCancellable?
    @State private var panDirection: PanDirection = .right

    private let transitionDuration: Double = 1.5
    private let imageDuration: Double = 6.0
    private let overscan: CGFloat = 1.25
    private let panFraction: CGFloat = 0.08

    private var isShowcase: Bool {
        UserDefaults.standard.string(forKey: "showcase") != nil
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black

                if !authManager.isAuthorized && !isShowcase {
                    unauthorizedView
                } else if !images.isEmpty {
                    artworkSlideshow(images, size: proxy.size)
                } else {
                    noMusicView
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .task { await loadAlbumsIfAuthorized() }
        .onChange(of: authManager.isAuthorized) { _, isAuthorized in
            if isAuthorized {
                Task { await loadAlbumsIfAuthorized() }
            }
        }
        .onChange(of: libraryStore.albums, initial: true) { _, albums in
            updateImages(with: albums)
        }
        .onChange(of: isActive) { _, isNowActive in
            if isNowActive {
                startImageCycle()
            } else {
                stopImageCycle()
            }
        }
        .onDisappear(perform: stopImageCycle)
    }

    private func updateImages(with albums: [LibraryItem]?) {
        var list: [ArtworkRef] = []

        if let albums {
            var matchingArtworks: [ArtworkRef] = []
            var otherArtworks: [ArtworkRef] = []

            for album in albums {
                guard let artwork = album.artwork else { continue }
                if Self.isHotFuss(album) {
                    matchingArtworks.append(artwork)
                } else {
                    otherArtworks.append(artwork)
                }
            }

            if !matchingArtworks.isEmpty {
                list = matchingArtworks + otherArtworks
            } else {
                list = [.asset(ImageNames.Custom.hotFuss)] + otherArtworks
            }
        } else {
            list = [.asset(ImageNames.Custom.hotFuss)]
        }

        images = list
        if currentImageIndex >= images.count { currentImageIndex = 0 }
        startImageCycle()
    }

    private static func isHotFuss(_ item: LibraryItem) -> Bool {
        let title = item.title.localizedLowercase
        let subtitle = item.subtitle.localizedLowercase
        return title.contains("hot fuss") ||
               title.contains("brightside") ||
               (subtitle.contains("the killers") && title.contains("fuss"))
    }

    private func loadAlbumsIfAuthorized() async {
        guard authManager.isAuthorized else { return }
        await libraryStore.loadAlbumsIfNeeded()
    }

    private var unauthorizedView: some View {
        VStack {
            Image(systemName: authManager.activeProviderID == .appleMusic ? "applelogo" : ImageNames.System.musicNote)
                .font(.system(size: 60))
                .foregroundColor(.white)
            Spacer().frame(height: 16)
            Text("Please sign in to \(authManager.activeProviderID.title)")
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .multilineTextAlignment(.center)
        }
    }

    private func artworkSlideshow(_ images: [ArtworkRef], size: CGSize) -> some View {
        let dimension = (max(size.width, size.height) * overscan).rounded()
        return ZStack {
            if currentImageIndex >= 0 && currentImageIndex < images.count {
                ArtworkView(artwork: images[currentImageIndex], width: dimension, height: dimension)
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .scaleEffect(overscan)
                    .modifier(PanEffect(
                        duration: imageDuration + transitionDuration,
                        direction: panDirection,
                        maxOffset: size.width * panFraction
                    ))
                    .id("\(currentImageIndex)-\(panDirection.rawValue)")
                    .transition(.opacity)
                    .animation(.easeInOut(duration: transitionDuration), value: currentImageIndex)
            }
        }
        .clipped()
    }

    private var noMusicView: some View {
        VStack {
            Image(systemName: ImageNames.System.musicNote)
                .resizable()
                .frame(width: 50, height: 90)
                .foregroundColor(.white)
            Spacer().frame(height: 16)
            Text("No Music")
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .bold))
        }
    }

    private func startImageCycle() {
        stopImageCycle()
        guard isActive, images.count > 1 else { return }
        timerCancellable = Timer.publish(every: imageDuration, on: .main, in: .common)
            .autoconnect()
            .sink { _ in transitionToNextImage() }
    }

    private func transitionToNextImage() {
        guard images.count > 1 else { return }

        withAnimation(.easeInOut(duration: transitionDuration)) {
            panDirection = panDirection == .right ? .left : .right
            currentImageIndex = (currentImageIndex + 1) % images.count
        }
    }

    private func stopImageCycle() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}

enum PanDirection: String, CaseIterable {
    case left
    case right
}

struct PanEffect: ViewModifier {
    let duration: Double
    let direction: PanDirection
    let maxOffset: CGFloat
    @State private var offset: CGFloat = 0

    private var startOffset: CGFloat {
        direction == .right ? -maxOffset : maxOffset
    }

    private var endOffset: CGFloat {
        direction == .right ? maxOffset : -maxOffset
    }

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onAppear {
                offset = startOffset
                withAnimation(.linear(duration: duration)) {
                    offset = endOffset
                }
            }
            .onChange(of: direction) {
                offset = startOffset
                withAnimation(.linear(duration: duration)) {
                    offset = endOffset
                }
            }
    }
}
