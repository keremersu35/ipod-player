import SwiftUI

struct DeviceBodyView: View {
    let theme: ThemeType

    var body: some View {
        LinearGradient(stops: theme.bodyStops, startPoint: .top, endPoint: .bottom)
            .overlay {
                AnodizedGrain(opacity: theme.grainOpacity)
            }
    }
}

struct AnodizedGrain: View {
    let opacity: Double

    var body: some View {
        Image(ImageNames.Custom.anodizedGrain)
            .resizable(resizingMode: .tile)
            .blendMode(.overlay)
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}

struct DeviceRim: View {
    let cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            shape
                .strokeBorder(
                    AngularGradient(
                        colors: [.white, .rimShade, .white.opacity(0.9), .rimShade.opacity(0.7), .white, .rimShade, .white],
                        center: .center
                    ),
                    lineWidth: 1.6
                )
            shape
                .inset(by: 1.6)
                .stroke(.black.opacity(0.18), lineWidth: 0.6)
        }
        .allowsHitTesting(false)
    }
}

struct DeviceSurroundView: View {
    let theme: ThemeType

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                surroundEdge
                RadialGradient(
                    colors: [surroundCenter, surroundEdge],
                    center: UnitPoint(x: 0.5, y: 0.42),
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.62
                )
            }
        }
    }

    static func prefersDarkStatusBar(for theme: ThemeType) -> Bool {
        theme == .silver
    }

    private var surroundCenter: Color {
        theme == .silver ? .surroundDarkTop : .surroundLightTop
    }

    private var surroundEdge: Color {
        theme == .silver ? .surroundDarkBottom : .surroundLightBottom
    }
}

struct DeviceFloorShadow: View {
    var body: some View {
        Ellipse()
            .fill(.black.opacity(0.45))
            .blur(radius: 14)
            .allowsHitTesting(false)
    }
}

struct ActualSizeDeviceBody: View {
    let theme: ThemeType
    let metrics: DeviceLayoutMetrics

    private var bodyShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
    }

    var body: some View {
        let size = metrics.bodySize
        ZStack(alignment: .topLeading) {
            DeviceBodyView(theme: theme)
                .overlay { keyLight }
                .overlay { edgeCurvature }
                .clipShape(bodyShape)
                .overlay(DeviceRim(cornerRadius: metrics.cornerRadius))
                .shadow(color: .black.opacity(0.28), radius: 2, y: 1.5)
                .shadow(color: .black.opacity(0.32), radius: 26, y: 18)
                .frame(width: size.width, height: size.height)

            ScreenWindowBevel(cornerRadius: metrics.screenCornerRadius)
                .frame(width: metrics.screenFrame.width, height: metrics.screenFrame.height)
                .offset(x: metrics.screenFrame.minX, y: metrics.screenFrame.minY)
        }
        .frame(width: size.width, height: size.height)
        .background(alignment: .bottom) {
            DeviceFloorShadow()
                .frame(width: size.width * 0.8, height: 28)
                .offset(y: 20)
        }
        .allowsHitTesting(false)
    }

    private var keyLight: some View {
        RadialGradient(
            colors: [.white.opacity(theme == .silver ? 0.16 : 0.10), .clear],
            center: UnitPoint(x: 0.28, y: 0.12),
            startRadius: 0,
            endRadius: metrics.bodySize.height * 0.7
        )
        .blendMode(.softLight)
    }

    private var edgeCurvature: some View {
        let band = metrics.bodySize.width * 0.032
        return ZStack {
            bodyShape
                .strokeBorder(.black.opacity(theme == .silver ? 0.30 : 0.45), lineWidth: band * 0.35)
                .blur(radius: band * 0.22)
                .blendMode(.multiply)
            bodyShape
                .inset(by: band * 0.28)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.75), location: 0),
                            .init(color: .white.opacity(0.35), location: 0.35),
                            .init(color: .white.opacity(0.18), location: 0.7),
                            .init(color: .white.opacity(0.06), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: band * 0.75
                )
                .blur(radius: band * 0.4)
                .blendMode(.softLight)
            bodyShape
                .strokeBorder(
                    LinearGradient(colors: [.clear, .clear, .black.opacity(0.22)], startPoint: .top, endPoint: .bottom),
                    lineWidth: band * 1.4
                )
                .blur(radius: band * 0.6)
                .blendMode(.multiply)
        }
    }
}

struct ScreenWindowBevel: View {
    let cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        ZStack {
            shape
                .inset(by: -2.5)
                .stroke(
                    LinearGradient(
                        colors: [.black.opacity(0.35), .black.opacity(0.12), .white.opacity(0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2.5
                )
                .blur(radius: 0.6)
            shape
                .inset(by: -0.6)
                .stroke(Color.screenSeam, lineWidth: 1.2)
        }
    }
}

struct ScreenGlassGlare: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.07), location: 0),
                .init(color: .white.opacity(0.025), location: 0.45),
                .init(color: .clear, location: 0.46),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .allowsHitTesting(false)
    }
}

