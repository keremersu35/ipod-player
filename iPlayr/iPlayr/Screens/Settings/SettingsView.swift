import SwiftUI

struct SettingsView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(PlaybackController.self) private var playerManager
    @Environment(ThemeManager.self) private var theme
    @Environment(\.navigate) private var navigate
    @AppStorage(UserDefaultsKeys.hapticsEnabled.rawValue) private var hapticsEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.soundsEnabled.rawValue) private var soundsEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.deviceLayout.rawValue) private var deviceLayout: DeviceLayout = .defaultValue
    @State private var scope = FocusScope(id: "settings")
    @State private var backlight = BacklightTimer.current

    private enum Row: CaseIterable {
        case about, shuffle, repeatMode, mainMenu, musicMenu, volumeLimit, backlight, brightness, display, sounds, haptics, themes, legal, reset
    }

    private func menu(for row: Row) -> Menu {
        switch row {
        case .about:
            return Menu(name: String(localized: "About"), next: true)
        case .shuffle:
            return Menu(name: String(localized: "Shuffle"), next: false, value: shuffleValue)
        case .repeatMode:
            return Menu(name: String(localized: "Repeat"), next: false, value: repeatValue)
        case .mainMenu:
            return Menu(name: String(localized: "Main Menu"), next: true)
        case .musicMenu:
            return Menu(name: String(localized: "Music Menu"), next: true)
        case .volumeLimit:
            return Menu(name: String(localized: "Volume Limit"), next: true)
        case .backlight:
            return Menu(name: String(localized: "Backlight"), next: false, value: backlight.shortTitle)
        case .brightness:
            return Menu(name: String(localized: "Brightness"), next: true)
        case .display:
            return Menu(name: String(localized: "Display"), next: false, value: deviceLayout.title)
        case .themes:
            return Menu(name: String(localized: "Themes"), next: true)
        case .haptics:
            return Menu(name: String(localized: "Haptics"), next: false, value: onOff(hapticsEnabled))
        case .sounds:
            return Menu(name: String(localized: "Clicker"), next: false, value: onOff(soundsEnabled))
        case .legal:
            return Menu(name: String(localized: "Legal"), next: true)
        case .reset:
            return Menu(name: String(localized: "Reset Settings"), next: true)
        }
    }

    private func pane(for row: Row) -> InfoPaneContent {
        switch row {
        case .about:
            return .storage(title: String(localized: "iPlayr"))
        case .shuffle:
            return .info(title: String(localized: "Shuffle"), icon: .symbol(ImageNames.System.shuffle), caption: shuffleValue)
        case .repeatMode:
            let symbol = playerManager.repeatMode == .one ? ImageNames.System.repeatOne : ImageNames.System.repeatAll
            return .info(title: String(localized: "Repeat"), icon: .symbol(symbol), caption: repeatValue)
        case .mainMenu:
            return .info(title: String(localized: "Main Menu"), icon: .menuList, caption: String(localized: "Customize Main Menu"))
        case .musicMenu:
            return .info(title: String(localized: "Music Menu"), icon: .menuList, caption: String(localized: "Customize Music Menu"))
        case .volumeLimit:
            return .info(title: String(localized: "Volume Limit"), icon: .symbol("speaker.wave.3.fill"), caption: volumeLimitValue)
        case .backlight:
            return .info(title: String(localized: "Backlight"), icon: .symbol("lightbulb.fill"), caption: backlight.title)
        case .display:
            return .info(title: String(localized: "Display"), icon: .symbol(deviceLayout == .actualSize ? "ipod" : "iphone"), caption: deviceLayout.title)
        case .brightness:
            return .info(title: String(localized: "Brightness"), icon: .symbol("sun.max.fill"), caption: String(localized: "Adjust Brightness"))
        case .sounds:
            return .info(title: String(localized: "Clicker"), icon: .symbol("speaker.wave.2.fill"), caption: onOff(soundsEnabled))
        case .haptics:
            return .info(title: String(localized: "Haptics"), icon: .symbol("iphone.radiowaves.left.and.right"), caption: onOff(hapticsEnabled))
        case .themes:
            return .info(title: String(localized: "Themes"), icon: .symbol("paintpalette.fill"), caption: themeName)
        case .legal:
            return .info(title: String(localized: "Legal"), icon: .symbol("doc.text.fill"), caption: String(localized: "Legal Notices"))
        case .reset:
            return .info(title: String(localized: "Reset Settings"), icon: .reset, caption: String(localized: "Reset All Settings"))
        }
    }

    private var currentRow: Row {
        Row.allCases[min(max(scope.selection, 0), Row.allCases.count - 1)]
    }

    private var themeName: String {
        switch theme.currentTheme {
        case .silver: return String(localized: "Silver")
        case .dark: return String(localized: "Black")
        case .u2Edition: return String(localized: "U2 Edition")
        }
    }

    private var volumeLimitValue: String {
        let limit = SystemVolume.limit
        return limit >= 1 ? String(localized: "Off") : limit.formatted(.percent.precision(.fractionLength(0)))
    }

    private var shuffleValue: String {
        playerManager.shuffleMode.title
    }

    private var repeatValue: String {
        switch playerManager.repeatMode {
        case .one: return String(localized: "One")
        case .all: return String(localized: "All")
        case .off: return String(localized: "Off")
        }
    }

    private func onOff(_ isOn: Bool) -> String {
        isOn ? String(localized: "On") : String(localized: "Off")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Settings"))
            ScrollIndicatedList(itemCount: Row.allCases.count, selection: scope.selection, rowHeight: MenuItemView.rowHeight) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(Row.allCases.enumerated()), id: \.offset) { index, row in
                                MenuItemView(menu: menu(for: row), isSelected: scope.selection == index)
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
        }
        .shadowedBackground()
        .infoPane(pane(for: currentRow))
        .onAppear(perform: setup)
    }

    private func setup() {
        scope.configure(itemCount: Row.allCases.count)
        scope.onAction = { handleButtonAction($0) }
        iPlayrController.activate(scope)
    }

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu:
            navigate(.pop)
        case .select:
            handleSelect()
        default:
            break
        }
    }

    private func handleSelect() {
        guard Row.allCases.indices.contains(scope.selection) else { return }
        switch Row.allCases[scope.selection] {
        case .about:
            navigate(.push(.about))
        case .shuffle:
            playerManager.setShuffleMode(playerManager.shuffleMode.next)
        case .volumeLimit:
            navigate(.push(.volumeLimit))
        case .backlight:
            backlight = backlight.next
            BacklightTimer.current = backlight
        case .repeatMode:
            playerManager.setRepeatMode(nextRepeatMode)
        case .mainMenu:
            navigate(.push(.menuCustomization(isMainMenu: true)))
        case .musicMenu:
            navigate(.push(.menuCustomization(isMainMenu: false)))
        case .brightness:
            navigate(.push(.brightness))
        case .display:
            deviceLayout = deviceLayout.next
        case .themes:
            navigate(.push(.theme))
        case .haptics:
            hapticsEnabled.toggle()
        case .sounds:
            soundsEnabled.toggle()
        case .legal:
            navigate(.push(.legal))
        case .reset:
            navigate(.push(.resetSettings))
        }
    }

    private var nextRepeatMode: RepeatMode {
        switch playerManager.repeatMode {
        case .off: return .all
        case .all: return .one
        case .one: return .off
        }
    }
}
