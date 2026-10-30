import SwiftUI

enum PaneIcon: Equatable, Sendable {
    case menuList
    case reset
    case symbol(String)
}

enum InfoPaneContent: Equatable, Sendable {
    case info(title: String, icon: PaneIcon, caption: String)
    case storage(title: String)
}

struct InfoPanePreferenceKey: PreferenceKey {
    static let defaultValue: InfoPaneContent? = nil

    static func reduce(value: inout InfoPaneContent?, nextValue: () -> InfoPaneContent?) {
        if let next = nextValue() { value = next }
    }
}

extension View {
    func infoPane(_ content: InfoPaneContent?) -> some View {
        preference(key: InfoPanePreferenceKey.self, value: content)
    }
}

struct InfoPaneView: View {
    let content: InfoPaneContent

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.iPod(20))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 22)
                .padding(.horizontal, 8)
            if case .info = content {
                Spacer(minLength: 0)
                    .frame(maxHeight: 50)
                centerpiece
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 8)
                centerpiece
                Spacer(minLength: 4)
            }
            Text(caption)
                .font(.iPod(14))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.horizontal, 8)
                .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.infoPaneTop, .infoPaneBottom], startPoint: .top, endPoint: .bottom)
        )
    }

    private var title: String {
        switch content {
        case .info(let title, _, _), .storage(let title): return title
        }
    }

    private var caption: String {
        switch content {
        case .info(_, _, let caption): return caption
        case .storage: return DeviceStorage.current.freeDescription
        }
    }

    @ViewBuilder
    private var centerpiece: some View {
        switch content {
        case .info(_, let icon, _):
            SettingsTile(icon: icon)
        case .storage:
            VStack(spacing: 12) {
                Image(systemName: "applelogo")
                    .font(.system(size: 60))
                    .foregroundStyle(LinearGradient(colors: [.white.opacity(0.95), .white.opacity(0.6)], startPoint: .top, endPoint: .bottom))
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                CapacityBar(usedFraction: DeviceStorage.current.usedFraction)
                    .frame(height: 8)
                    .padding(.horizontal, 18)
            }
        }
    }
}

struct CapacityBar: View {
    let usedFraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.85))
                Capsule()
                    .fill(LinearGradient(colors: [.menuItemBackground1, .menuItemBackground5], startPoint: .top, endPoint: .bottom))
                    .frame(width: proxy.size.width * min(max(usedFraction, 0), 1))
            }
            .overlay(Capsule().stroke(.black.opacity(0.25), lineWidth: 0.5))
        }
    }
}

struct DeviceStorage {
    let total: Int64
    let available: Int64

    static var current: DeviceStorage {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityForImportantUsageKey])
        let total = Int64(values?.volumeTotalCapacity ?? 0)
        let available = values?.volumeAvailableCapacityForImportantUsage ?? 0
        return DeviceStorage(total: total, available: available)
    }

    var used: Int64 { max(total - available, 0) }
    var usedFraction: Double { total > 0 ? Double(used) / Double(total) : 0 }

    var freeDescription: String {
        String(localized: "\(Self.format(available)) Free")
    }

    var usedDescription: String {
        String(localized: "\(Self.format(used)) Used")
    }

    static func format(_ bytes: Int64) -> String {
        bytes.formatted(.byteCount(style: .file))
    }
}

struct SettingsTile: View {
    let icon: PaneIcon

    private static let side: CGFloat = 78 * iPodBitmap.pointsPerPixel
    private static let reflectionHeight: CGFloat = 43 * iPodBitmap.pointsPerPixel

    var body: some View {
        VStack(spacing: 1) {
            tile
            tile
                .scaleEffect(x: 1, y: -1)
                .frame(height: Self.reflectionHeight, alignment: .top)
                .clipped()
                .mask(LinearGradient(colors: [.black.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom))
        }
    }

    private var tile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                .fill(LinearGradient(stops: [
                    .init(color: Color(red: 0.42, green: 0.44, blue: 0.47), location: 0),
                    .init(color: Color(red: 0.24, green: 0.25, blue: 0.27), location: 0.3),
                    .init(color: Color(red: 0.15, green: 0.15, blue: 0.17), location: 0.55),
                    .init(color: Color(red: 0.10, green: 0.10, blue: 0.11), location: 1),
                ], startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.22), .black.opacity(0.3)], startPoint: .top, endPoint: .bottom), lineWidth: 0.8)
            glyph
                .foregroundStyle(LinearGradient(colors: [Color(white: 0.92), Color(white: 0.78)], startPoint: .top, endPoint: .bottom))
        }
        .frame(width: Self.side, height: Self.side)
    }

    @ViewBuilder
    private var glyph: some View {
        switch icon {
        case .menuList:
            MenuListGlyph()
                .frame(width: Self.side * 0.64, height: Self.side * 0.6)
                .offset(x: Self.side * 0.03)
        case .reset:
            ResetGlyph()
                .frame(width: Self.side * 0.6, height: Self.side * 0.6)
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: Self.side * 0.46, weight: .semibold))
        }
    }
}

private struct MenuListGlyph: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
                if index > 0 { Spacer(minLength: 0) }
                Capsule()
                    .frame(height: 11)
                    .overlay {
                        Capsule()
                            .fill(.black.opacity(0.12))
                            .frame(height: 2)
                            .padding(.leading, 6)
                            .padding(.trailing, 14)
                    }
                    .overlay(alignment: .trailing) {
                        ChevronShapeView()
                            .frame(width: 4, height: 7)
                            .padding(.trailing, 5)
                    }
            }
        }
    }
}

private struct ChevronShapeView: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 4, y: 3.5))
            path.addLine(to: CGPoint(x: 0, y: 7))
        }
        .stroke(Color(white: 0.15), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
    }
}

private struct ResetGlyph: View {
    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let ring = side * 0.19
            let radius = (side - ring) / 2
            let end = Angle.degrees(-40)
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.84)
                    .stroke(style: StrokeStyle(lineWidth: ring, lineCap: .butt))
                    .rotationEffect(end)
                    .padding(ring / 2)
                ResetArrowHead()
                    .frame(width: ring * 1.6, height: ring * 2.2)
                    .rotationEffect(.degrees(-130))
                    .position(x: side / 2 + radius * cos(end.radians), y: side / 2 + radius * sin(end.radians))
                Circle()
                    .frame(width: side * 0.27, height: side * 0.27)
            }
            .frame(width: side, height: side)
        }
    }
}

private struct ResetArrowHead: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.1, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
