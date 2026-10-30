import SwiftUI

enum WheelGlyphKind {
    case previous
    case next
    case playPause

    var aspectRatio: CGFloat {
        switch self {
        case .previous, .next: return 94 / 50
        case .playPause: return 116 / 51
        }
    }
}

struct WheelGlyph: Shape {
    let kind: WheelGlyphKind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .next:
            return skipPath(in: rect)
        case .previous:
            return skipPath(in: rect)
                .applying(CGAffineTransform(a: -1, b: 0, c: 0, d: 1, tx: rect.minX * 2 + rect.width, ty: 0))
        case .playPause:
            return playPausePath(in: rect)
        }
    }

    private func skipPath(in rect: CGRect) -> Path {
        let sx = rect.width / 94
        let sy = rect.height / 50
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy) }
        var path = Path()
        path.addLines([p(0, 1), p(40, 25), p(0, 49)])
        path.closeSubpath()
        path.addLines([p(40, 1), p(80, 25), p(40, 49)])
        path.closeSubpath()
        path.addRect(CGRect(origin: p(80, 0), size: CGSize(width: 13 * sx, height: 50 * sy)))
        return path
    }

    private func playPausePath(in rect: CGRect) -> Path {
        let sx = rect.width / 116
        let sy = rect.height / 51
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * sx, y: rect.minY + y * sy) }
        var path = Path()
        path.addLines([p(0, 2.5), p(47, 25.5), p(0, 48.5)])
        path.closeSubpath()
        let radius = 2 * min(sx, sy)
        path.addRoundedRect(in: CGRect(origin: p(74, 0), size: CGSize(width: 14 * sx, height: 51 * sy)), cornerSize: CGSize(width: radius, height: radius))
        path.addRoundedRect(in: CGRect(origin: p(101, 0), size: CGSize(width: 15 * sx, height: 51 * sy)), cornerSize: CGSize(width: radius, height: radius))
        return path
    }
}

struct ChevronGlyph: View {
    var body: some View {
        ChevronShape()
            .stroke(style: StrokeStyle(lineWidth: 2.6, lineCap: .butt, lineJoin: .miter))
            .frame(width: 7, height: 14)
    }
}

private struct ChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addLines([
            CGPoint(x: rect.minX + 1, y: rect.minY + 1),
            CGPoint(x: rect.maxX - 1, y: rect.midY),
            CGPoint(x: rect.minX + 1, y: rect.maxY - 1),
        ])
        return path
    }
}

struct iPodBitmap: View {
    static let pointsPerPixel = iPlayrScreen.screenHeight / 240

    let name: String
    let pixelSize: CGSize

    var body: some View {
        Image(name)
            .resizable()
            .interpolation(.high)
            .renderingMode(.template)
            .frame(width: pixelSize.width * Self.pointsPerPixel, height: pixelSize.height * Self.pointsPerPixel)
    }

    static let shuffle = iPodBitmap(name: ImageNames.Custom.nowPlayingShuffle, pixelSize: CGSize(width: 18, height: 14))
    static let repeatAll = iPodBitmap(name: ImageNames.Custom.nowPlayingRepeat, pixelSize: CGSize(width: 19, height: 15))
    static let repeatOne = iPodBitmap(name: ImageNames.Custom.nowPlayingRepeatOnce, pixelSize: CGSize(width: 19, height: 15))
    static let volumeLow = iPodBitmap(name: ImageNames.Custom.volumeLow, pixelSize: CGSize(width: 9, height: 17))
    static let volumeHigh = iPodBitmap(name: ImageNames.Custom.volumeHigh, pixelSize: CGSize(width: 19, height: 17))
}
