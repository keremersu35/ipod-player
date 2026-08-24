import SwiftUI

struct CollectionMenuModel: Equatable {
    let artwork: ArtworkRef?
    let name: String
    let description: String
}

struct CollectionMenuItem: View {
    var model: CollectionMenuModel
    var isSelected: Bool

    var body: some View {
        HStack {
            artworkView
            VStack(alignment: .leading) {
                Text(model.name)
                    .font(.system(size: 16))
                    .fontWeight(.bold)
                Text(model.description)
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
        ArtworkView(artwork: model.artwork, width: 50, height: 50)
    }
}
