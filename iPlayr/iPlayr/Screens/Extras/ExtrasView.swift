import SwiftUI

struct ExtrasView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "extras")

    private enum Entry: CaseIterable {
        case clocks, stopwatch, screenLock

        var title: String {
            switch self {
            case .clocks: return String(localized: "Clocks")
            case .stopwatch: return String(localized: "Stopwatch")
            case .screenLock: return String(localized: "Screen Lock")
            }
        }

        var route: Route {
            switch self {
            case .clocks: return .clocks
            case .stopwatch: return .stopwatch
            case .screenLock: return .screenLock
            }
        }

        var pane: InfoPaneContent {
            switch self {
            case .clocks:
                return .info(title: title, icon: .symbol("clock.fill"), caption: Date.now.formatted(date: .omitted, time: .shortened))
            case .stopwatch:
                return .info(title: title, icon: .symbol("stopwatch.fill"), caption: String(localized: "Time Laps"))
            case .screenLock:
                return .info(title: title, icon: .symbol("lock.fill"), caption: String(localized: "Lock Your iPlayr"))
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Extras"))
            ForEach(Array(Entry.allCases.enumerated()), id: \.offset) { index, entry in
                MenuItemView(menu: Menu(name: entry.title, next: true), isSelected: scope.selection == index)
            }
            Spacer()
        }
        .shadowedBackground()
        .infoPane(Entry.allCases[min(scope.selection, Entry.allCases.count - 1)].pane)
        .onAppear(perform: setup)
    }

    private func setup() {
        scope.configure(itemCount: Entry.allCases.count)
        scope.onAction = { action in
            switch action {
            case .menu:
                navigate(.pop)
            case .select:
                navigate(.push(Entry.allCases[scope.selection].route))
            default:
                break
            }
        }
        iPlayrController.activate(scope)
    }
}

struct ExtrasBackground: View {
    var body: some View {
        LinearGradient(colors: [.aboutBackgroundTop, .infoPaneBottom], startPoint: .top, endPoint: .bottom)
    }
}
