import SwiftUI

struct MenuCustomizationView: View {
    let isMainMenu: Bool

    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(MenuPreferences.self) private var menuPreferences
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "menuCustomization")

    private var items: [MusicMenuItem] { MusicMenuItem.allCases }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: isMainMenu ? String(localized: "Main Menu") : String(localized: "Music Menu"))
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(items.indices, id: \.self) { index in
                            MenuItemView(menu: menu(at: index), isSelected: scope.selection == index)
                                .id(index)
                        }
                        MenuItemView(menu: Menu(name: String(localized: "Reset Menu"), next: false), isSelected: scope.selection == items.count)
                            .id(items.count)
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
    }

    private func menu(at index: Int) -> Menu {
        let item = items[index]
        let isEnabled = isMainMenu ? menuPreferences.isInMainMenu(item) : menuPreferences.isInMusicMenu(item)
        return Menu(name: item.title, next: false, value: isEnabled ? "✓" : nil)
    }

    private func setup() {
        scope.configure(itemCount: items.count + 1)
        scope.onAction = { handleButtonAction($0) }
        iPlayrController.activate(scope)
    }

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu:
            navigate(.pop)
        case .select:
            guard scope.selection < items.count else {
                isMainMenu ? menuPreferences.resetMainMenu() : menuPreferences.resetMusicMenu()
                return
            }
            let item = items[scope.selection]
            isMainMenu ? menuPreferences.toggleMainMenu(item) : menuPreferences.toggleMusicMenu(item)
        default:
            break
        }
    }
}
