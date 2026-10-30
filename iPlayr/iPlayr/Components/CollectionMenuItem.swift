import SwiftUI

struct CollectionMenuItem: View {
    static let rowHeight: CGFloat = 50

    var item: LibraryItem
    var isSelected: Bool

    var body: some View {
        HStack {
            artworkView
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.iPod(iPodTypeScale.listTitle))
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.iPod(iPodTypeScale.listSubtitle, bold: false))
                    .lineLimit(1)
            }
            Spacer()
            if isSelected {
                ChevronGlyph()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: Self.rowHeight)
        .padding(.trailing, 8)
        .foregroundColor(isSelected ? .white : .black)
        .background(SelectionBackground(isSelected: isSelected))
    }

    private var artworkView: some View {
        ArtworkView(artwork: item.artwork, width: 50, height: 50)
    }
}
