import CoreGraphics
import Foundation

enum DeviceLayout: String, CaseIterable, Sendable {
    case fullScreen
    case actualSize

    var title: String {
        switch self {
        case .fullScreen: return String(localized: "Full Screen")
        case .actualSize: return String(localized: "Actual Size")
        }
    }

    var next: DeviceLayout {
        self == .fullScreen ? .actualSize : .fullScreen
    }
}

struct DeviceLayoutMetrics {
    static let bodyAspect: CGFloat = 103.5 / 61.8
    static let screenWidthRatio: CGFloat = 0.869
    static let screenTopRatio: CGFloat = 0.043
    static let screenAspect: CGFloat = 0.75
    static let wheelDiameterRatio: CGFloat = 0.631
    static let wheelCenterRatio: CGFloat = 0.707
    static let cornerRadiusRatio: CGFloat = 0.105
    static let screenCornerRatio: CGFloat = 0.02

    let bodySize: CGSize
    let screenSize: CGSize
    let screenScale: CGFloat
    let screenFrame: CGRect
    let wheelBox: CGSize
    let wheelDiameter: CGFloat
    let wheelCenterY: CGFloat

    var cornerRadius: CGFloat { bodySize.width * Self.cornerRadiusRatio }
    var screenCornerRadius: CGFloat { bodySize.width * Self.screenCornerRatio }

    init(layout: DeviceLayout, container: CGSize, screenDesignHeight: CGFloat, wheelBoxRatio: CGFloat) {
        let width = min(container.width, container.height / Self.bodyAspect)
        let height = width * Self.bodyAspect
        bodySize = CGSize(width: width, height: height)

        let screenWidth = width * Self.screenWidthRatio
        let screenHeight = screenWidth * Self.screenAspect
        screenScale = screenHeight / screenDesignHeight
        screenSize = CGSize(width: screenWidth / screenScale, height: screenDesignHeight)
        screenFrame = CGRect(
            x: (width - screenWidth) / 2,
            y: height * Self.screenTopRatio,
            width: screenWidth,
            height: screenHeight
        )

        wheelDiameter = width * Self.wheelDiameterRatio
        let boxWidth = wheelDiameter / wheelBoxRatio
        wheelBox = CGSize(width: boxWidth, height: boxWidth * 0.9)
        wheelCenterY = height * Self.wheelCenterRatio
    }
}
