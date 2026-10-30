import SwiftUI

extension Font {
    static func iPod(_ size: CGFloat, bold: Bool = true) -> Font {
        .custom(bold ? "HelveticaNeue-Bold" : "HelveticaNeue", fixedSize: size)
    }
}

enum iPodTypeScale {
    static let menuRow: CGFloat = 18
    static let menuValue: CGFloat = 16
    static let statusTitle: CGFloat = 15
    static let listTitle: CGFloat = 17
    static let listSubtitle: CGFloat = 14
    static let nowPlayingTitle: CGFloat = 20
    static let nowPlayingDetail: CGFloat = 16
    static let nowPlayingPosition: CGFloat = 15
}
