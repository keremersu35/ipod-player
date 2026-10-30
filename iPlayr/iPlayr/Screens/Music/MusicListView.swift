import SwiftUI

struct MusicListView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(PlaybackController.self) private var playerManager
    @Environment(MenuPreferences.self) private var menuPreferences
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "music")

    private var entries: [(menu: Menu, route: Route)] {
        var entries = menuPreferences.musicMenu.map {
            (Menu(name: $0.title, next: true), $0.route)
        }
        if playerManager.currentTrack != nil {
            entries.append((Menu(name: String(localized: "Now Playing"), next: true), .nowPlaying))
        }
        return entries
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Music"))
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(entries.indices, id: \.self) { index in
                            MenuItemView(menu: entries[index].0, isSelected: scope.selection == index)
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
        case .menu:
            navigate(.pop)
        case .select:
            guard entries.indices.contains(scope.selection) else { return }
            navigate(.push(entries[scope.selection].1))
        default: break
        }
    }
}
