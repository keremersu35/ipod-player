import SwiftUI

struct StatusBar: View {
    static let height: CGFloat = 26

    @Environment(PlaybackController.self) private var playerManager
    var title: String
    @State private var batteryLevel = UIDevice.current.batteryLevel

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text(title)
                    .foregroundColor(.black)
                    .font(.iPod(iPodTypeScale.statusTitle))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if playerManager.isPlaying || playerManager.isPaused {
                    Image(playerManager.isPlaying ? ImageNames.Custom.play : ImageNames.Custom.pause)
                        .resizable()
                        .frame(width: 12, height: 14)
                    Spacer()
                        .frame(width: 8)
                }
                BatteryIconView(level: CGFloat(batteryLevel))
                    .frame(width: 28, height: 14)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: Self.height - 1)
            .background(
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .statusBar1, location: 0),
                                .init(color: .statusBar2, location: 0.42),
                                .init(color: .statusBar3, location: 0.47),
                                .init(color: .statusBar4, location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: Self.height - 1)
            )
            Rectangle()
                .fill(.statusBarDivider)
                .frame(maxWidth: .infinity, maxHeight: 1)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)) { _ in
            batteryLevel = UIDevice.current.batteryLevel
        }
    }
}

struct BatteryIconView: View {
    var level: CGFloat

    private static let lowChargeThreshold: CGFloat = 0.2
    private let greenFill: [Color] = [.batteryFill1, .batteryFill2, .batteryFill3, .batteryFill4, .batteryFill5,
                                      .batteryFill6, .batteryFill7, .batteryFill8, .batteryFill9, .batteryFill10]
    private let redFill: [Color] = [.batteryRed1, .batteryRed2, .batteryRed3, .batteryRed4, .batteryRed5,
                                    .batteryRed6, .batteryRed7, .batteryRed8, .batteryRed9, .batteryRed10]
    private let batteryEmpty: [Color] = [.batteryEmpty1, .batteryEmpty2, .batteryEmpty3]

    private var fillGradient: LinearGradient {
        let colors = level < Self.lowChargeThreshold ? redFill : greenFill
        let bandSize = colors.count / 2
        let stops = colors.enumerated().map { index, color -> Gradient.Stop in
            let bandStart = index < bandSize ? 0.0 : 0.5
            let position = Double(index % bandSize) / Double(bandSize - 1)
            return .init(color: color, location: bandStart + position * 0.5)
        }
        return LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }

    private var emptyGradient: LinearGradient {
        LinearGradient(colors: batteryEmpty, startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(emptyGradient)
                .frame(width: 24, height: 12)

            Rectangle()
                .fill(fillGradient)
                .frame(width: max(0, 24 * level), height: 12)

            Rectangle()
                .stroke(.batteryOutline, lineWidth: 1)
                .frame(width: 24, height: 12)

            Rectangle()
                .fill(.batteryNub)
                .frame(width: 3, height: 5)
                .border(.batteryOutline, width: 0.5)
                .offset(x: 24)
        }
        .padding(2)
        .frame(width: 28, height: 14)
    }
}
