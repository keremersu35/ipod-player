import SwiftUI

struct iPlayrView: View {
    @State private var iPlayrController: iPlayrButtonController = .init()
    @Environment(ThemeManager.self) private var theme
    @Environment(PlaybackController.self) private var playerManager

    var body: some View {
        VStack() {
            Spacer()
            iPlayrScreen()
                .environment(iPlayrController)
                .padding(.horizontal)
                .environment(theme)
            Spacer()
            iPlayrButtons()
                .environment(iPlayrController)
                .environment(theme)
            Spacer()
        }
        .background(
            Image(theme.currentTheme.caseAppearance)
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        )
        .onAppear {
            iPlayrController.setGlobalPlaybackHandler { action in
                Task {
                    switch action {
                    case .playPause: try? await playerManager.togglePlayPause()
                    case .forwardEndAlt: try? await playerManager.skipToNextTrack()
                    case .backwardEndAlt: try? await playerManager.skipToPreviousTrack()
                    default: break
                    }
                }
            }
        }
    }
}
