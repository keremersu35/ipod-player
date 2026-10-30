import Foundation
import UIKit
import AudioToolbox
import Observation

enum ButtonAction: Hashable, Sendable {
    case menu, forwardEndAlt, backwardEndAlt, playPause, select, selectLongPress
    case forwardLongPress, backwardLongPress, forwardLongPressEnd, backwardLongPressEnd
}

@MainActor
@Observable
final class iPlayrButtonController {
    private(set) var activeScope: FocusScope?

    @ObservationIgnored private var globalPlaybackHandler: ((ButtonAction) -> Void)?
    @ObservationIgnored var onMenuLongPress: (() -> Void)?
    var isInputLocked = false
    @ObservationIgnored private var activityHandlers: [UUID: () -> Void] = [:]

    @ObservationIgnored private let selectionFeedback = UISelectionFeedbackGenerator()
    @ObservationIgnored private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    private var hapticsEnabled: Bool { UserDefaults.standard.object(forKey: UserDefaultsKeys.hapticsEnabled.rawValue) as? Bool ?? true }
    private var soundsEnabled: Bool { UserDefaults.standard.object(forKey: UserDefaultsKeys.soundsEnabled.rawValue) as? Bool ?? true }

    @ObservationIgnored private var lastInteractionTime: Date = .distantPast
    @ObservationIgnored private let debounceInterval: TimeInterval = 0.3

    init() {
        selectionFeedback.prepare()
        impactFeedback.prepare()
    }

    func activate(_ scope: FocusScope) {
        activeScope = scope
    }

    func observeActivity(_ id: UUID, handler: (() -> Void)?) {
        activityHandlers[id] = handler
    }

    private func notifyActivity() {
        for handler in activityHandlers.values { handler() }
    }

    func setGlobalPlaybackHandler(_ handler: @escaping (ButtonAction) -> Void) {
        self.globalPlaybackHandler = handler
    }

    private func playPressFeedback() {
        if hapticsEnabled {
            impactFeedback.impactOccurred()
            impactFeedback.prepare()
        }
        if soundsEnabled {
            AudioServicesPlaySystemSound(1306)
        }
    }

    private func consumeDebounce() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastInteractionTime) > debounceInterval else { return false }
        lastInteractionTime = now
        return true
    }

    private func handleInput(_ action: ButtonAction) {
        notifyActivity()
        if action == .menu || action == .select || action == .selectLongPress {
            guard consumeDebounce() else { return }
            playPressFeedback()
        }

        activeScope?.onAction?(action)

        switch action {
        case .playPause, .forwardEndAlt, .backwardEndAlt:
            if activeScope?.handledTransportActions.contains(action) != true {
                globalPlaybackHandler?(action)
            }
        default:
            break
        }
    }

    func menuButtonPressed() { handleInput(.menu) }

    func menuLongPressed() {
        notifyActivity()
        guard !isInputLocked, consumeDebounce() else { return }
        playPressFeedback()
        onMenuLongPress?()
    }

    func selectButtonPressed() { handleInput(.select) }
    func selectLongPressed() { handleInput(.selectLongPress) }
    func forwardEndAltButtonPressed() { handleInput(.forwardEndAlt) }
    func backwardEndAltButtonPressed() { handleInput(.backwardEndAlt) }
    func playPauseButtonPressed() { handleInput(.playPause) }

    func forwardLongPressStarted() { handleInput(.forwardLongPress) }
    func forwardLongPressEnded() { handleInput(.forwardLongPressEnd) }
    func backwardLongPressStarted() { handleInput(.backwardLongPress) }
    func backwardLongPressEnded() { handleInput(.backwardLongPressEnd) }

    func scrollUp() {
        notifyActivity()
        guard let scope = activeScope, scope.moveUp() else { return }
        if hapticsEnabled {
            selectionFeedback.selectionChanged()
            selectionFeedback.prepare()
        }
    }

    func scrollDown() {
        notifyActivity()
        guard let scope = activeScope, scope.moveDown() else { return }
        if hapticsEnabled {
            selectionFeedback.selectionChanged()
            selectionFeedback.prepare()
        }
    }
}
