import SwiftUI

struct StopwatchView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "stopwatch", handledTransportActions: [.playPause])
    @State private var accumulated: TimeInterval = 0
    @State private var startedAt: Date?
    @State private var laps: [TimeInterval] = []

    private var isRunning: Bool { startedAt != nil }

    var body: some View {
        VStack(spacing: 0) {
            StatusBar(title: String(localized: "Stopwatch"))
            ZStack {
                ExtrasBackground()
                TimelineView(.periodic(from: .now, by: isRunning ? 0.05 : 3600)) { context in
                    VStack(spacing: 10) {
                        HStack(spacing: 14) {
                            Image(systemName: "stopwatch")
                                .font(.system(size: 54, weight: .light))
                            Text(Self.format(elapsed(at: context.date)))
                                .font(.system(size: 30, weight: .bold))
                                .monospacedDigit()
                                .minimumScaleFactor(0.6)
                                .lineLimit(1)
                        }
                        if !laps.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(Array(laps.enumerated().reversed().prefix(3)), id: \.offset) { index, lap in
                                    Text("Lap \(index + 1)  \(Self.format(lap))")
                                        .font(.system(size: 13, weight: .bold))
                                        .monospacedDigit()
                                }
                            }
                        }
                        Text(isRunning ? String(localized: "Center: Lap · ▶︎❙❙: Pause") : String(localized: "▶︎❙❙: Start · Center: Reset"))
                            .font(.system(size: 11, weight: .bold))
                            .opacity(0.8)
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                }
            }
        }
        .onAppear(perform: setup)
    }

    private func elapsed(at date: Date) -> TimeInterval {
        accumulated + (startedAt.map { date.timeIntervalSince($0) } ?? 0)
    }

    private func setup() {
        scope.onAction = { action in
            switch action {
            case .menu:
                navigate(.pop)
            case .playPause:
                if let startedAt {
                    accumulated += Date.now.timeIntervalSince(startedAt)
                    self.startedAt = nil
                } else {
                    startedAt = .now
                }
            case .select:
                if isRunning {
                    laps.append(elapsed(at: .now))
                } else {
                    accumulated = 0
                    laps = []
                }
            default:
                break
            }
        }
        iPlayrController.activate(scope)
    }

    static func format(_ interval: TimeInterval) -> String {
        let hundredths = Int((interval * 100).rounded(.down))
        let hours = hundredths / 360_000
        let minutes = hundredths / 6000 % 60
        let seconds = hundredths / 100 % 60
        return String(format: "%02d:%02d:%02d.%02d", hours, minutes, seconds, hundredths % 100)
    }
}
