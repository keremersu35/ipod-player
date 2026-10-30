import SwiftUI

enum NowPlayingMode: CaseIterable {
    case progress
    case scrubber
    case rating
    case shuffle

    var next: NowPlayingMode {
        let all = Self.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[(index + 1) % all.count]
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

struct BarTrack: View {
    static let height: CGFloat = 18

    let progress: Double
    var playhead: Double?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                background
                if playhead == nil {
                    fill
                        .frame(width: geo.size.width * min(max(progress, 0), 1), height: Self.height)
                }
                if let playhead {
                    Diamond()
                        .fill(Color.scrubberPlayhead)
                        .frame(width: Self.height * 0.62, height: Self.height * 0.62)
                        .offset(x: geo.size.width * min(max(playhead, 0), 1) - Self.height * 0.31)
                        .frame(height: Self.height)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: Self.height)
        .reflection()
    }

    private var background: some View {
        ZStack {
            Rectangle()
                .fill(Color(.white).gradient.shadow(.inner(color: .black.opacity(0.1), radius: 10, x: 0, y: -2)))
                .frame(height: Self.height)
            Rectangle()
                .fill(Color(.white).gradient.shadow(.inner(color: .black.opacity(0.2), radius: 10, x: 0, y: 2)))
                .frame(height: Self.height)
        }
    }

    private var fill: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .progressFill1, location: 0),
                        .init(color: .progressFill2, location: 0.20),
                        .init(color: .progressFill3, location: 0.58),
                        .init(color: .progressFill4, location: 0.58),
                        .init(color: .progressFill5, location: 0.82),
                        .init(color: .progressFill6, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .shadow(.inner(color: .white.opacity(0.3), radius: 4, x: 0, y: 1))
            )
    }
}

enum NowPlayingBarMetrics {
    static let height: CGFloat = 34
    static let sideWidth: CGFloat = 50
}

struct NowPlayingBar<Leading: View, Trailing: View>: View {
    let progress: Double
    var playhead: Double?
    let leading: Leading
    let trailing: Trailing

    init(progress: Double, playhead: Double? = nil, @ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.progress = progress
        self.playhead = playhead
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 0) {
            leading
                .frame(width: NowPlayingBarMetrics.sideWidth, alignment: .leading)
            BarTrack(progress: progress, playhead: playhead)
                .padding(8)
            trailing
                .frame(width: NowPlayingBarMetrics.sideWidth, alignment: .trailing)
        }
        .frame(maxWidth: .infinity)
        .frame(height: NowPlayingBarMetrics.height)
    }
}

struct ScrubberView: View {
    @Environment(PlaybackController.self) private var playerManager

    private var duration: TimeInterval { playerManager.currentTrack?.duration ?? 0 }

    private var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, playerManager.currentPlaybackTime / duration)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: playerManager.isPlaying ? 0.1 : 3600)) { _ in
            NowPlayingBar(progress: progress, playhead: progress) {
                TimeLabel(seconds: Int(progress * duration))
            } trailing: {
                TimeLabel(seconds: Int(duration - progress * duration), isRemaining: true)
            }
        }
    }
}

struct VolumeBarView: View {
    let level: Float

    var body: some View {
        NowPlayingBar(progress: Double(level)) {
            iPodBitmap.volumeLow
                .foregroundColor(.black)
        } trailing: {
            iPodBitmap.volumeHigh
                .foregroundColor(.black)
        }
    }
}

struct TimeLabel: View {
    let seconds: Int
    var isRemaining: Bool = false

    var body: some View {
        Text(isRemaining ? "-\(formatted)" : formatted)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(.black)
            .monospacedDigit()
            .lineLimit(1)
    }

    private var formatted: String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

struct RatingBarView: View {
    let rating: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...RatingStore.maxRating, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "circle.fill")
                    .font(.system(size: star <= rating ? 18 : 5))
                    .foregroundStyle(star <= rating ? Color.black : Color.gray.opacity(0.6))
                    .frame(width: 22, height: 22)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: NowPlayingBarMetrics.height)
    }
}

struct ShuffleBarView: View {
    let mode: ShuffleMode

    var body: some View {
        HStack(spacing: 8) {
            Text("Shuffle")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.black)
            HStack(spacing: 0) {
                ForEach(ShuffleMode.allCases, id: \.self) { option in
                    Text(option.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(option == mode ? .white : .black)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            if option == mode { SelectedRowBackground() }
                        }
                }
            }
            .frame(height: 24)
            .background(RoundedRectangle(cornerRadius: 5).fill(.white))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(.gray.opacity(0.6), lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
        .frame(height: NowPlayingBarMetrics.height)
    }
}

struct ContextMenuOverlay: View {
    let title: String
    let options: [String]
    let selection: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(spacing: 0) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.black)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .frame(height: 24)
                    .background(LinearGradient(colors: [.statusBar1, .statusBar4], startPoint: .top, endPoint: .bottom))
                ForEach(options.indices, id: \.self) { index in
                    MenuItemView(menu: Menu(name: options[index], next: false), isSelected: index == selection)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black.opacity(0.5), lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            .padding(.horizontal, 36)
        }
    }
}

struct IdleClockView: View {
    var body: some View {
        TimelineView(.everyMinute) { context in
            VStack(spacing: 6) {
                Text(context.date.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 64, weight: .bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                Text(context.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.gray)
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
    }
}
