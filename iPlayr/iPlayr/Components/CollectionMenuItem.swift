import SwiftUI

struct CollectionMenuItem: View {
    var item: LibraryItem
    var isSelected: Bool

    var body: some View {
        HStack {
            artworkView
            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.system(size: 16))
                    .fontWeight(.bold)
                Text(item.subtitle)
                    .font(.system(size: 14))
                    .fontWeight(.regular)
            }
            Spacer()
            if isSelected {
                Image(systemName: ImageNames.System.chevronRight)
                    .font(.system(size: 14))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 50)
        .padding(.trailing, 8)
        .foregroundColor(isSelected ? .white : .black)
        .background(
            Group {
                if isSelected {
                    SelectedRowBackground()
                } else {
                    Rectangle()
                        .fill(.white)
                }
            }
        )
    }

    private var artworkView: some View {
        ArtworkView(artwork: item.artwork, width: 50, height: 50)
    }
}
