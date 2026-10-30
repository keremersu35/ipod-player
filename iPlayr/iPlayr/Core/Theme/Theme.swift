import SwiftUI

enum ThemeType: String, CaseIterable {
    case silver, dark, u2Edition

    var wheelIconTint: Color {
        switch self {
        case .silver: return .buttonIconTint
        case .dark, .u2Edition: return .wheelIconLight
        }
    }

    var bodyStops: [Gradient.Stop] {
        switch self {
        case .silver:
            return [
                .init(color: .bodySilver1, location: 0),
                .init(color: .bodySilver2, location: 0.45),
                .init(color: .bodySilver3, location: 0.6),
                .init(color: .bodySilver4, location: 0.8),
                .init(color: .bodySilver5, location: 1),
            ]
        case .dark, .u2Edition:
            return [
                .init(color: .bodyDark1, location: 0),
                .init(color: .bodyDark2, location: 0.45),
                .init(color: .bodyDark3, location: 0.6),
                .init(color: .bodyDark4, location: 0.8),
                .init(color: .bodyDark5, location: 1),
            ]
        }
    }

    var centerButtonBrightness: Double {
        switch self {
        case .silver: return 0
        case .dark, .u2Edition: return -0.07
        }
    }

    var grainOpacity: Double {
        switch self {
        case .silver: return 0.7
        case .dark, .u2Edition: return 0.3
        }
    }

    var wheelColor: Color {
        switch self {
        case .silver: return .wheelSilver
        case .dark: return .wheelDark
        case .u2Edition: return .wheelU2
        }
    }

    var wheelInnerAppearance: String {
        switch self {
        case .silver: return ImageNames.Custom.lightThemeButton
        case .dark, .u2Edition: return ImageNames.Custom.darkThemeButton
        }
    }
}

@MainActor
@Observable
final class ThemeManager {
    private(set) var currentTheme: ThemeType

    init() {
        let saved = UserDefaults.standard.string(forKey: UserDefaultsKeys.currentTheme.rawValue).flatMap(ThemeType.init)
        currentTheme = saved ?? .silver
    }

    func setTheme(_ themeType: ThemeType) {
        currentTheme = themeType
        UserDefaults.standard.set(themeType.rawValue, forKey: UserDefaultsKeys.currentTheme.rawValue)
    }
}
