import SwiftUI

struct ScrollIndicatedList<Content: View>: View {
    let itemCount: Int
    let selection: Int
    let rowHeight: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let overflows = CGFloat(itemCount) * rowHeight > proxy.size.height
            HStack(spacing: 0) {
                content()
                if overflows {
                    ListScrollIndicator(
                        selection: selection,
                        itemCount: itemCount,
                        visibleFraction: proxy.size.height / (CGFloat(itemCount) * rowHeight)
                    )
                    .frame(width: ListScrollIndicator.width)
                }
            }
        }
    }
}

struct ListScrollIndicator: View {
    static let width: CGFloat = 7

    let selection: Int
    let itemCount: Int
    let visibleFraction: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let trackHeight = proxy.size.height
            let thumbHeight = max(14, trackHeight * min(visibleFraction, 1))
            let progress = itemCount > 1 ? CGFloat(selection) / CGFloat(itemCount - 1) : 0
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.scrollTrack)
                    .overlay(alignment: .leading) {
                        Rectangle().fill(.statusBarDivider.opacity(0.5)).frame(width: 1)
                    }
                RoundedRectangle(cornerRadius: 2)
                    .fill(LinearGradient(colors: [.scrollThumb.opacity(0.75), .scrollThumb], startPoint: .leading, endPoint: .trailing))
                    .frame(width: Self.width - 3, height: thumbHeight)
                    .offset(x: 1, y: (trackHeight - thumbHeight) * progress)
            }
        }
    }
}

extension ScrollViewProxy {
    func jump<ID: Hashable>(to id: ID, anchor: UnitPoint? = nil) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            scrollTo(id, anchor: anchor)
        }
    }
}
