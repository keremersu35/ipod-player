import SwiftUI

struct ClockView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "clocks")

    private var cityName: String {
        let identifier = TimeZone.current.identifier
        return identifier.split(separator: "/").last.map { $0.replacingOccurrences(of: "_", with: " ") } ?? identifier
    }

    var body: some View {
        VStack(spacing: 0) {
            StatusBar(title: String(localized: "Clocks"))
            TimelineView(.periodic(from: .now, by: 1)) { context in
                ZStack {
                    ExtrasBackground()
                    VStack(spacing: 14) {
                        HStack(alignment: .center, spacing: 12) {
                            Text(cityName)
                                .font(.system(size: 18, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            AnalogClockFace(date: context.date)
                                .frame(width: 92, height: 92)
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(context.date.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 18, weight: .bold))
                                    .monospacedDigit()
                                Text("Today")
                                    .font(.system(size: 13, weight: .bold))
                                    .opacity(0.85)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        Text(context.date.formatted(.dateTime.weekday(.wide).day().month(.wide).year()))
                            .font(.system(size: 13, weight: .bold))
                            .opacity(0.9)
                    }
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear(perform: setup)
    }

    private func setup() {
        scope.onAction = { action in
            if action == .menu { navigate(.pop) }
        }
        iPlayrController.activate(scope)
    }
}

struct AnalogClockFace: View {
    let date: Date

    private var components: DateComponents {
        Calendar.current.dateComponents([.hour, .minute, .second], from: date)
    }

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let hour = Double(components.hour ?? 0).truncatingRemainder(dividingBy: 12)
            let minute = Double(components.minute ?? 0)
            let second = Double(components.second ?? 0)
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.white, .statusBar2], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
                ForEach(0..<12, id: \.self) { tick in
                    Capsule()
                        .fill(.black.opacity(0.7))
                        .frame(width: 2, height: size * 0.08)
                        .offset(y: -size * 0.4)
                        .rotationEffect(.degrees(Double(tick) * 30))
                }
                hand(width: 3.5, length: size * 0.26, angle: (hour + minute / 60) * 30, color: .black)
                hand(width: 2.5, length: size * 0.38, angle: (minute + second / 60) * 6, color: .black)
                hand(width: 1, length: size * 0.42, angle: second * 6, color: .red)
                Circle().fill(.black).frame(width: 6, height: 6)
            }
            .frame(width: size, height: size)
        }
    }

    private func hand(width: CGFloat, length: CGFloat, angle: Double, color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
            .rotationEffect(.degrees(angle))
    }
}
