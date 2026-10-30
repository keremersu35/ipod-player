import SwiftUI

struct LegalView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "legal")

    private let paragraphs: [String] = [
        String(localized: "iPlayr is an independent project and is not affiliated with, sponsored or endorsed by Apple Inc."),
        String(localized: "iPod, Click Wheel, Cover Flow, Apple Music and iTunes are trademarks of Apple Inc., registered in the U.S. and other countries."),
        String(localized: "Music playback and library access are provided by Apple Music through MusicKit. An active Apple Music subscription is required to play catalog content."),
        String(localized: "Album artwork and metadata are supplied by your music service and remain the property of their respective owners."),
        String(localized: "This software is provided \"as is\", without warranty of any kind.")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Legal"))
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(paragraphs.indices, id: \.self) { index in
                            Text(paragraphs[index])
                                .font(.system(size: 13))
                                .foregroundStyle(.black)
                                .fixedSize(horizontal: false, vertical: true)
                                .id(index)
                        }
                    }
                    .padding(12)
                }
                .scrollIndicators(.hidden)
                .onChange(of: scope.selection) { _, newIndex in
                    withAnimation { proxy.scrollTo(newIndex, anchor: .top) }
                }
            }
        }
        .background(Color.white)
        .onAppear(perform: setup)
    }

    private func setup() {
        scope.configure(itemCount: paragraphs.count)
        scope.onAction = { action in
            if action == .menu { navigate(.pop) }
        }
        iPlayrController.activate(scope)
    }
}
