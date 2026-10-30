import SwiftUI

struct OnTheGoView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(OnTheGoStore.self) private var onTheGo
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "onTheGo")

    private var rowCount: Int { onTheGo.items.isEmpty ? 0 : onTheGo.items.count + 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "On-The-Go"))
            if onTheGo.items.isEmpty {
                StateView(state: .empty(message: String(localized: "No songs in On-The-Go\nHold the center button on a song to add it")))
            } else {
                ScrollIndicatedList(itemCount: rowCount, selection: scope.selection, rowHeight: MenuItemView.rowHeight) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(onTheGo.items.indices, id: \.self) { index in
                                    MenuItemView(menu: Menu(name: onTheGo.items[index].title, next: false), isSelected: scope.selection == index)
                                        .id(index)
                                }
                                MenuItemView(menu: Menu(name: String(localized: "Clear Playlist"), next: false), isSelected: scope.selection == onTheGo.items.count)
                                    .id(onTheGo.items.count)
                            }
                        }
                        .scrollIndicators(.hidden)
                        .onChange(of: scope.selection) { _, newIndex in
                            proxy.jump(to: newIndex)
                        }
                    }
                }
            }
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .onChange(of: rowCount) { _, count in
            scope.itemCount = count
        }
    }

    private func setup() {
        scope.configure(itemCount: rowCount)
        scope.onAction = { action in
            switch action {
            case .menu:
                navigate(.pop)
            case .select:
                if scope.selection == onTheGo.items.count {
                    onTheGo.clear()
                } else if onTheGo.items.indices.contains(scope.selection) {
                    navigate(.push(.player(source: .onTheGo, trackIndex: scope.selection)))
                }
            default:
                break
            }
        }
        iPlayrController.activate(scope)
    }
}
