import SwiftUI

struct iPlayrView: View {
    @State private var iPlayrController: iPlayrButtonController = .init()
    @Environment(ThemeManager.self) private var theme
    @Environment(PlaybackController.self) private var playerManager
    @AppStorage(UserDefaultsKeys.deviceLayout.rawValue) private var deviceLayout: DeviceLayout = .defaultValue

    private var isActualSize: Bool { deviceLayout == .actualSize }

    private var prefersDarkChrome: Bool {
        if isActualSize {
            return DeviceSurroundView.prefersDarkStatusBar(for: theme.currentTheme)
        }
        return theme.currentTheme != .silver
    }

    var body: some View {
        GeometryReader { proxy in
            let metrics = DeviceLayoutMetrics(
                layout: deviceLayout,
                container: proxy.size,
                screenDesignHeight: iPlayrScreen.screenHeight,
                wheelBoxRatio: iPlayrButtons.wheelDiameterRatio
            )
            let layout = isActualSize ? AnyLayout(ActualSizeDeviceLayout(metrics: metrics)) : AnyLayout(VStackLayout())

            ZStack {
                if isActualSize {
                    ActualSizeDeviceBody(theme: theme.currentTheme, metrics: metrics)
                }
                layout {
                    Spacer()
                    iPlayrScreen()
                        .environment(iPlayrController)
                        .overlay {
                            if isActualSize {
                                ScreenGlassGlare()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .scaleEffect(isActualSize ? metrics.screenScale : 1)
                        .padding(.horizontal, isActualSize ? 0 : 16)
                        .environment(theme)
                    Spacer()
                    iPlayrButtons()
                        .environment(iPlayrController)
                        .environment(theme)
                    Spacer()
                }
            }
        }
        .background {
            if isActualSize {
                DeviceSurroundView(theme: theme.currentTheme)
                    .ignoresSafeArea()
            } else {
                DeviceBodyView(theme: theme.currentTheme)
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: deviceLayout)
        .preferredColorScheme(prefersDarkChrome ? .dark : .light)
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
            #if SHOWCASE
            ShowcaseRunner.startIfRequested(controller: iPlayrController)
            #endif
        }
    }
}

struct ActualSizeDeviceLayout: Layout {
    let metrics: DeviceLayoutMetrics

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let origin = CGPoint(
            x: bounds.midX - metrics.bodySize.width / 2,
            y: bounds.midY - metrics.bodySize.height / 2
        )
        for (index, subview) in subviews.enumerated() {
            switch index {
            case 1:
                let center = CGPoint(x: bounds.midX, y: origin.y + metrics.screenFrame.midY)
                subview.place(at: center, anchor: .center, proposal: ProposedViewSize(metrics.screenSize))
            case 3:
                let center = CGPoint(x: bounds.midX, y: origin.y + metrics.wheelCenterY)
                subview.place(at: center, anchor: .center, proposal: ProposedViewSize(metrics.wheelBox))
            default:
                subview.place(at: CGPoint(x: bounds.midX, y: bounds.midY), anchor: .center, proposal: .zero)
            }
        }
    }
}
