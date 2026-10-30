import Foundation
import SwiftUI

enum NavigationType: Hashable, Sendable {
    case push(Route)
    case pop
    case popToRoot
}

struct NavigateAction: Sendable {
    typealias Action = @MainActor @Sendable (NavigationType) -> Void
    let action: Action

    @MainActor
    func callAsFunction(_ navigationType: NavigationType) {
        action(navigationType)
    }
}

struct NavigationEnvironmentKey: EnvironmentKey {
    static let defaultValue: NavigateAction = NavigateAction(action: { _ in })
}

struct IsNavigatingEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var navigate: NavigateAction {
        get { self[NavigationEnvironmentKey.self] }
        set { self[NavigationEnvironmentKey.self] = newValue }
    }

    var isNavigating: Bool {
        get { self[IsNavigatingEnvironmentKey.self] }
        set { self[IsNavigatingEnvironmentKey.self] = newValue }
    }
}

extension View {
    func taskAfterNavigation(_ action: @escaping @MainActor @Sendable () async -> Void) -> some View {
        modifier(TaskAfterNavigation(action: action))
    }
}

private struct TaskAfterNavigation: ViewModifier {
    @Environment(\.isNavigating) private var isNavigating
    @State private var hasRun = false
    let action: @MainActor @Sendable () async -> Void

    func body(content: Content) -> some View {
        content.task(id: isNavigating) {
            guard !isNavigating, !hasRun else { return }
            hasRun = true
            await action()
        }
    }
}

enum PlaybackSource: Hashable, Sendable {
    case album(id: String)
    case playlist(id: String)
    case composer(name: String)
    case allSongs
    case shuffleAll
    case onTheGo
}

enum Route: Hashable, Identifiable, Sendable {
    case music
    case home
    case playlists
    case artists(genre: CollectionInfoModel?)
    case albums
    case songs
    case genres
    case composers
    case artistAlbums(artist: CollectionInfoModel)
    case playlistTracks(playlist: CollectionInfoModel)
    case albumTracks(album: CollectionInfoModel)
    case composerSongs(composer: String)
    case about
    case legal
    case search
    case onTheGo
    case extras
    case clocks
    case stopwatch
    case screenLock
    case volumeLimit
    case resetSettings
    case brightness
    case menuCustomization(isMainMenu: Bool)
    case signIn
    case coverFlow
    case theme
    case player(source: PlaybackSource, trackIndex: Int, isFromCoverFlow: Bool = false)
    case settings
    case nowPlaying

    var id: Route { self }
}

extension Route {
    var isFullScreen: Bool {
        switch self {
        case .home, .music, .settings, .signIn, .theme,
             .brightness, .menuCustomization, .extras, .volumeLimit:
            return false
        case .playlists, .artists, .albums, .songs, .genres, .composers,
             .artistAlbums, .playlistTracks, .albumTracks, .composerSongs,
             .coverFlow, .player, .nowPlaying, .about, .legal, .resetSettings,
             .search, .onTheGo, .clocks, .stopwatch, .screenLock:
            return true
        }
    }

    @MainActor @ViewBuilder
    var destination: some View {
        switch self {
        case .music:
            MusicListView()
        case .home:
            HomeListView()
        case .playlists:
            PlaylistsView()
        case .artists(let genre):
            ArtistsView(genre: genre)
        case .albums:
            AlbumsView()
        case .songs:
            SongsView()
        case .genres:
            GenresView()
        case .composers:
            ComposersView()
        case .artistAlbums(let artist):
            ArtistAlbumsView(artist: artist)
        case .playlistTracks(let playlist):
            PlaylistTracksView(playlist: playlist)
        case .albumTracks(let album):
            AlbumTracksView(album: album)
        case .composerSongs(let composer):
            ComposerSongsView(composer: composer)
        case .about:
            AboutView()
        case .legal:
            LegalView()
        case .search:
            SearchView()
        case .onTheGo:
            OnTheGoView()
        case .extras:
            ExtrasView()
        case .clocks:
            ClockView()
        case .stopwatch:
            StopwatchView()
        case .screenLock:
            ScreenLockView()
        case .volumeLimit:
            VolumeLimitView()
        case .resetSettings:
            ResetSettingsView()
        case .brightness:
            BrightnessView()
        case .menuCustomization(let isMainMenu):
            MenuCustomizationView(isMainMenu: isMainMenu)
        case .signIn:
            SignInView()
        case .coverFlow:
            CoverFlowView()
        case .theme:
            ThemeView()
        case .player(let source, let trackIndex, let isFromCoverFlow):
            PlayerView(source: source, trackIndex: trackIndex, isFromCoverFlow: isFromCoverFlow)
        case .nowPlaying:
            PlayerView(source: nil, trackIndex: 0, isFromCoverFlow: false)
        case .settings:
            SettingsView()
        }
    }
}
