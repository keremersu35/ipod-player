import Foundation
import Observation
import SwiftUI

enum BacklightTimer: Int, CaseIterable, Sendable {
    case twoSeconds = 2
    case fiveSeconds = 5
    case tenSeconds = 10
    case fifteenSeconds = 15
    case twentySeconds = 20
    case thirtySeconds = 30
    case alwaysOn = 0

    static let defaultValue: BacklightTimer = .tenSeconds

    static var current: BacklightTimer {
        get {
            let raw = UserDefaults.standard.object(forKey: UserDefaultsKeys.backlightTimer.rawValue) as? Int
            return raw.flatMap(BacklightTimer.init(rawValue:)) ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaultsKeys.backlightTimer.rawValue)
        }
    }

    var timeout: Duration? {
        self == .alwaysOn ? nil : .seconds(rawValue)
    }

    var title: String {
        self == .alwaysOn ? String(localized: "Always On") : String(localized: "\(rawValue) Seconds")
    }

    var shortTitle: String {
        self == .alwaysOn ? String(localized: "Always") : String(localized: "\(rawValue) sec")
    }

    var next: BacklightTimer {
        let all = Self.allCases
        return all[((all.firstIndex(of: self) ?? 0) + 1) % all.count]
    }
}

@MainActor
@Observable
final class InactivityTimer {
    private(set) var hasElapsed = false

    @ObservationIgnored let id = UUID()
    @ObservationIgnored private var task: Task<Void, Never>?

    func restart(after delay: Duration?, wakeAnimation: Animation? = nil, elapseAnimation: Animation? = nil, shouldElapse: @escaping @MainActor () -> Bool = { true }) {
        task?.cancel()
        if hasElapsed {
            withAnimation(wakeAnimation) { hasElapsed = false }
        }
        guard let delay else { return }
        task = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled, let self, shouldElapse() else { return }
            withAnimation(elapseAnimation) { self.hasElapsed = true }
        }
    }

    func reset() {
        task?.cancel()
        hasElapsed = false
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
