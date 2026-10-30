import SwiftUI

struct Menu: Identifiable, Equatable {
    var id: Int = 0
    let name: String
    let next: Bool
    var value: String? = nil
}

struct MenuItemView: View {
    static let rowHeight: CGFloat = 31

    var menu: Menu
    var isSelected: Bool

    var body: some View {
        HStack {
            Text(menu.name)
                .font(.iPod(iPodTypeScale.menuRow))
                .lineLimit(1)
            Spacer()
            if let value = menu.value {
                Text(value)
                    .font(.iPod(iPodTypeScale.menuValue))
                    .foregroundStyle(isSelected ? .white : .blue)
            } else if menu.next && isSelected {
                ChevronGlyph()
            }
        }
        .padding(.horizontal, 8)
        .frame(height: Self.rowHeight)
        .foregroundColor(isSelected ? .white : .black)
        .background(SelectionBackground(isSelected: isSelected))
    }
}

struct SelectionBackground: View {
    let isSelected: Bool

    var body: some View {
        Group {
            if isSelected {
                SelectedRowBackground()
            } else {
                Rectangle()
                    .fill(.white)
            }
        }
    }
}

struct SelectedRowBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.menuItemBackground1,
                     .menuItemBackground2,
                     .menuItemBackground3,
                     .menuItemBackground4,
                     .menuItemBackground5],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.menuItemHighlight)
                .frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.menuItemRule)
                .frame(height: 1)
        }
    }
}
