import SwiftUI

struct ScreenLockView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "screenLock", handledTransportActions: [.playPause, .forwardEndAlt, .backwardEndAlt])
    @State private var phase: Phase = .menu
    @State private var digits = [0, 0, 0, 0]
    @State private var cursor = 0
    @State private var isWrong = false

    private static let digitCount = 4

    private enum Phase {
        case menu, setting, locked
    }

    private enum MenuRow: Int, CaseIterable {
        case lock, reset

        var title: String {
            switch self {
            case .lock: return String(localized: "Lock")
            case .reset: return String(localized: "Reset Combination")
            }
        }
    }

    private var savedCombination: [Int]? {
        guard let raw = UserDefaults.standard.string(forKey: UserDefaultsKeys.screenLockCombination.rawValue),
              raw.count == Self.digitCount else { return nil }
        return raw.compactMap(\.wholeNumberValue)
    }

    var body: some View {
        VStack(spacing: 0) {
            StatusBar(title: String(localized: "Screen Lock"))
            switch phase {
            case .menu:
                VStack(spacing: 0) {
                    ForEach(MenuRow.allCases, id: \.rawValue) { row in
                        MenuItemView(menu: Menu(name: row.title, next: false), isSelected: scope.selection == row.rawValue)
                    }
                    Spacer()
                }
                .background(Color.white)
            case .setting, .locked:
                combinationPad
            }
        }
        .onAppear(perform: setup)
        .onDisappear { iPlayrController.isInputLocked = false }
    }

    private var combinationPad: some View {
        ZStack {
            ExtrasBackground()
            VStack(spacing: 16) {
                HStack(spacing: 18) {
                    Image(systemName: phase == .locked ? "lock.fill" : "lock.open.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(LinearGradient(colors: [.statusBar1, .statusBar4], startPoint: .top, endPoint: .bottom))
                        .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
                    HStack(spacing: 6) {
                        ForEach(0..<Self.digitCount, id: \.self) { index in
                            Text(String(digits[index]))
                                .font(.system(size: 26, weight: .bold))
                                .monospacedDigit()
                                .foregroundStyle(index == cursor ? .white : .black)
                                .frame(width: 30, height: 40)
                                .background {
                                    if index == cursor {
                                        SelectedRowBackground()
                                    } else {
                                        LinearGradient(colors: [.white, .statusBar3], startPoint: .top, endPoint: .bottom)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.75)))
                    .offset(x: isWrong ? 8 : 0)
                }
                Text(phase == .locked ? String(localized: "Enter Combination") : String(localized: "New Combination"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
            }
        }
    }

    private func setup() {
        if savedCombination == nil {
            startSetting()
        } else {
            scope.configure(itemCount: MenuRow.allCases.count)
        }
        scope.onScroll = { handleScroll($0) }
        scope.onAction = { handleAction($0) }
        iPlayrController.activate(scope)
    }

    private func handleScroll(_ delta: Int) -> Bool {
        switch phase {
        case .menu:
            let target = min(max(scope.selection + delta, 0), MenuRow.allCases.count - 1)
            guard target != scope.selection else { return false }
            scope.select(target)
        case .setting, .locked:
            digits[cursor] = (digits[cursor] + delta + 10) % 10
        }
        return true
    }

    private func handleAction(_ action: ButtonAction) {
        switch phase {
        case .menu:
            switch action {
            case .menu:
                navigate(.pop)
            case .select:
                if scope.selection == MenuRow.lock.rawValue {
                    lock()
                } else {
                    startSetting()
                }
            default:
                break
            }
        case .setting:
            switch action {
            case .menu:
                navigate(.pop)
            case .select:
                advance { combination in
                    UserDefaults.standard.set(combination.map(String.init).joined(), forKey: UserDefaultsKeys.screenLockCombination.rawValue)
                    lock()
                }
            case .backwardEndAlt:
                cursor = max(cursor - 1, 0)
            default:
                break
            }
        case .locked:
            switch action {
            case .select:
                advance { combination in
                    if combination == savedCombination {
                        iPlayrController.isInputLocked = false
                        navigate(.pop)
                    } else {
                        rejectAttempt()
                    }
                }
            case .backwardEndAlt:
                cursor = max(cursor - 1, 0)
            default:
                break
            }
        }
    }

    private func advance(onComplete: ([Int]) -> Void) {
        if cursor < Self.digitCount - 1 {
            cursor += 1
        } else {
            onComplete(digits)
        }
    }

    private func startSetting() {
        digits = Array(repeating: 0, count: Self.digitCount)
        cursor = 0
        phase = .setting
    }

    private func lock() {
        digits = Array(repeating: 0, count: Self.digitCount)
        cursor = 0
        phase = .locked
        iPlayrController.isInputLocked = true
    }

    private func rejectAttempt() {
        withAnimation(.default.repeatCount(3, autoreverses: true).speed(4)) { isWrong = true }
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            isWrong = false
            digits = Array(repeating: 0, count: Self.digitCount)
            cursor = 0
        }
    }
}
