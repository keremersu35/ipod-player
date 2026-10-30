import SwiftUI

struct HomeListView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(MusicAccountManager.self) private var authManager
    @Environment(PlaybackController.self) private var playerManager
    @Environment(MenuPreferences.self) private var menuPreferences
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "home")

    private var entries: [(menu: Menu, route: Route)] {
        var entries: [(menu: Menu, route: Route)] = [
            (.init(name: String(localized: "Music"), next: true), .music),
        ]
        entries += menuPreferences.mainMenuShortcuts.map {
            (Menu(name: $0.title, next: true), $0.route)
        }
        entries += [
            (.init(name: String(localized: "Extras"), next: true), .extras),
            (.init(name: String(localized: "Settings"), next: true), .settings),
            (.init(name: String(localized: "Shuffle Songs"), next: false), .player(source: .shuffleAll, trackIndex: 0)),
        ]
        if !authManager.isAuthorized {
            entries.append((.init(name: String(localized: "Sign In"), next: true), .signIn))
        }
        if playerManager.currentTrack != nil {
            entries.append((.init(name: String(localized: "Now Playing"), next: true), .nowPlaying))
        }
        return entries
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "iPlayr"))
            ForEach(entries.indices, id: \.self) { index in
                MenuItemView(menu: entries[index].menu, isSelected: scope.selection == index)
            }
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .onChange(of: entries.count) { _, count in
            scope.itemCount = count
        }
    }

    private func setup() {
        scope.configure(itemCount: entries.count)
        scope.onAction = { handleButtonAction($0) }
        iPlayrController.activate(scope)
    }

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .select:
            guard entries.indices.contains(scope.selection) else { return }
            navigate(.push(entries[scope.selection].route))
        default: break
        }
    }
}
