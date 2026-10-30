import SwiftUI

struct ResetSettingsView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(PlaybackController.self) private var playerManager
    @Environment(MenuPreferences.self) private var menuPreferences
    @Environment(ThemeManager.self) private var theme
    @Environment(\.navigate) private var navigate
    @AppStorage(UserDefaultsKeys.hapticsEnabled.rawValue) private var hapticsEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.soundsEnabled.rawValue) private var soundsEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.deviceLayout.rawValue) private var deviceLayout: DeviceLayout = .fullScreen
    @State private var scope = FocusScope(id: "resetSettings")

    private enum Choice: Int, CaseIterable {
        case reset, cancel

        var title: String {
            switch self {
            case .reset: return String(localized: "Reset")
            case .cancel: return String(localized: "Cancel")
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Reset Settings"))
            VStack(alignment: .leading, spacing: 8) {
                Text("Do you want to reset your iPlayr?")
                    .font(.system(size: 17, weight: .bold))
                Text("This will reset all your settings. Your music library will not be modified.")
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            Spacer()
            choiceBar
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
        }
        .foregroundStyle(.black)
        .background(Color.white)
        .onAppear(perform: setup)
    }

    private var choiceBar: some View {
        HStack(spacing: 6) {
            ForEach(Choice.allCases, id: \.rawValue) { choice in
                let isSelected = scope.selection == choice.rawValue
                Text(choice.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 84, height: 26)
                    .background {
                        if isSelected {
                            SelectedRowBackground()
                        } else {
                            LinearGradient(colors: [.gray.opacity(0.75), .black.opacity(0.75)], startPoint: .top, endPoint: .bottom)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: [.statusBar1, .statusBar4], startPoint: .top, endPoint: .bottom))
        )
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.statusBarDivider.opacity(0.6), lineWidth: 1))
    }

    private func setup() {
        scope.configure(itemCount: Choice.allCases.count, selection: Choice.cancel.rawValue)
        scope.onAction = { action in
            switch action {
            case .menu:
                navigate(.pop)
            case .select:
                if scope.selection == Choice.reset.rawValue { resetAll() }
                navigate(.pop)
            default:
                break
            }
        }
        iPlayrController.activate(scope)
    }

    private func resetAll() {
        menuPreferences.resetMusicMenu()
        menuPreferences.resetMainMenu()
        playerManager.setShuffleMode(.off)
        playerManager.setRepeatMode(.off)
        hapticsEnabled = true
        soundsEnabled = true
        theme.setTheme(.silver)
        BacklightTimer.current = .defaultValue
        deviceLayout = .fullScreen
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.volumeLimit.rawValue)
    }
}
