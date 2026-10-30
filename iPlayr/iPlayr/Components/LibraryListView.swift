import SwiftUI

struct LibraryListView<Item, Row: View>: View {
    let title: String
    let emptyMessage: String
    let rowHeight: CGFloat
    let cached: () -> [Item]?
    let load: () async -> [Item]?
    let onSelect: (Item, Int) -> Void
    let onHold: ((Item) -> String?)?
    let indexTitle: ((Item) -> String)?
    let row: (Item, Bool) -> Row

    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(MusicLibraryStore.self) private var libraryStore
    @Environment(\.navigate) private var navigate
    @State private var scope: FocusScope
    @State private var viewState: ViewState = .loading
    @State private var items: [Item] = []
    @State private var fastScroll = FastScrollTracker()
    @State private var indexLetter: String?
    @State private var toast: String?

    init(
        title: String,
        scopeID: String,
        emptyMessage: String,
        rowHeight: CGFloat = MenuItemView.rowHeight,
        cached: @escaping () -> [Item]? = { nil },
        load: @escaping () async -> [Item]?,
        onSelect: @escaping (Item, Int) -> Void,
        onHold: ((Item) -> String?)? = nil,
        indexTitle: ((Item) -> String)? = nil,
        @ViewBuilder row: @escaping (Item, Bool) -> Row
    ) {
        self.title = title
        self.emptyMessage = emptyMessage
        self.rowHeight = rowHeight
        self.cached = cached
        self.load = load
        self.onSelect = onSelect
        self.onHold = onHold
        self.indexTitle = indexTitle
        self.row = row
        _scope = State(initialValue: FocusScope(id: scopeID))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: title)
            ZStack {
                if viewState == .content {
                    itemList
                }
                StateView(state: viewState)
                if let indexLetter {
                    FastScrollLetterView(letter: indexLetter)
                        .transition(.opacity)
                }
                if let toast {
                    ToastView(message: toast)
                        .transition(.opacity)
                }
            }
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .taskAfterNavigation { await loadItems() }
        .task(id: indexLetter) {
            guard indexLetter != nil else { return }
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { indexLetter = nil }
        }
        .task(id: toast) {
            guard toast != nil else { return }
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { toast = nil }
        }
    }

    private var itemList: some View {
        ScrollIndicatedList(itemCount: items.count, selection: scope.selection, rowHeight: rowHeight) {
            scrollingRows
        }
    }

    private var scrollingRows: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { index in
                        row(items[index], index == scope.selection)
                            .id(index)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .onChange(of: scope.selection) { _, newIndex in
                proxy.jump(to: newIndex)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    proxy.jump(to: scope.selection)
                }
            }
        }
    }

    private func setup() {
        scope.onAction = { handleButtonAction($0) }
        if indexTitle != nil {
            scope.onScroll = { handleScroll($0) }
        }
        iPlayrController.activate(scope)
        applyCachedItems()
    }

    private func applyCachedItems() {
        guard let cachedItems = cached(), !cachedItems.isEmpty else { return }
        items = cachedItems
        scope.configure(itemCount: cachedItems.count)
        viewState = .content
    }

    private func loadItems() async {
        guard viewState != .content else { return }
        viewState = .loading

        guard let loadedItems = await load() else {
            viewState = .error(message: libraryStore.errorMessage ?? String(localized: "An error occurred\nPlease try again later"))
            return
        }

        items = loadedItems
        guard !loadedItems.isEmpty else {
            viewState = .empty(message: emptyMessage)
            return
        }
        scope.configure(itemCount: loadedItems.count)
        viewState = .content
    }

    private func handleScroll(_ delta: Int) -> Bool {
        guard let indexTitle, !items.isEmpty else { return false }
        let current = scope.selection
        let target: Int
        if fastScroll.register() && items.count > FastScrollTracker.minimumItems {
            target = FastScrollTracker.letterBoundary(from: current, step: delta, count: items.count) {
                FastScrollTracker.initial(of: indexTitle(items[$0]))
            }
            withAnimation(.easeOut(duration: 0.1)) {
                indexLetter = FastScrollTracker.initial(of: indexTitle(items[target]))
            }
        } else {
            target = min(max(current + delta, 0), items.count - 1)
        }
        guard target != current else { return false }
        scope.select(target)
        return true
    }

    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu:
            navigate(.pop)
        case .select:
            guard items.indices.contains(scope.selection) else { return }
            onSelect(items[scope.selection], scope.selection)
        case .selectLongPress:
            guard let onHold, items.indices.contains(scope.selection),
                  let message = onHold(items[scope.selection]) else { return }
            withAnimation(.easeOut(duration: 0.15)) { toast = message }
        default:
            break
        }
    }
}

@MainActor
final class FastScrollTracker {
    static let minimumItems = 30
    private static let window: TimeInterval = 0.45
    private static let threshold = 5

    private var timestamps: [Date] = []

    func register() -> Bool {
        let now = Date()
        timestamps.append(now)
        timestamps.removeAll { now.timeIntervalSince($0) > Self.window }
        return timestamps.count >= Self.threshold
    }

    static func initial(of title: String) -> String {
        guard let first = title.trimmingCharacters(in: .whitespaces).first else { return "#" }
        return first.isLetter ? String(first).uppercased() : "#"
    }

    static func letterBoundary(from index: Int, step: Int, count: Int, initial: (Int) -> String) -> Int {
        let currentLetter = initial(index)
        var cursor = index
        if step > 0 {
            while cursor < count - 1 && initial(cursor) == currentLetter { cursor += 1 }
            return cursor
        }
        while cursor > 0 && initial(cursor - 1) == currentLetter { cursor -= 1 }
        if cursor == index && cursor > 0 {
            let previousLetter = initial(cursor - 1)
            cursor -= 1
            while cursor > 0 && initial(cursor - 1) == previousLetter { cursor -= 1 }
        }
        return cursor
    }
}

struct FastScrollLetterView: View {
    let letter: String

    var body: some View {
        Text(letter)
            .font(.system(size: 56, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: 92, height: 92)
            .background(RoundedRectangle(cornerRadius: 14).fill(.black.opacity(0.7)))
            .allowsHitTesting(false)
    }
}

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 10).fill(.black.opacity(0.75)))
            .allowsHitTesting(false)
    }
}
