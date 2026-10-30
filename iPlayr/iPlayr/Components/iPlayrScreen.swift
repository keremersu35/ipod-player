import SwiftUI

struct iPlayrScreen: View {
    static let screenHeight: CGFloat = 300
    static let pointsPerPixel: CGFloat = screenHeight / 240
    private static let pushAnimation: Animation = .easeInOut(duration: 0.28)

    @State private var menu = NavigationLayer(root: .home)
    @State private var fullScreen = NavigationLayer()
    @State private var isNavigating = false
    @State private var infoPane: InfoPaneContent?
    @State private var backlight = InactivityTimer()
    @Environment(iPlayrButtonController.self) private var iPlayrController

    private var isFullScreen: Bool { !fullScreen.isEmpty }

    var body: some View {
        GeometryReader { geometry in
            contentView(geometry: geometry)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(height: Self.screenHeight)
                .overlay {
                    if backlight.hasElapsed {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.black.opacity(0.55))
                            .allowsHitTesting(false)
                            .transition(.opacity)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 6)
                        .foregroundColor(.screenFrame)
                )
        }
        .environment(\.isNavigating, isNavigating)
        .onNavigate(handleNavigation)
        .onAppear {
            iPlayrController.onMenuLongPress = { handleNavigation(.popToRoot) }
            let backlight = backlight
            let wake = {
                backlight.restart(
                    after: BacklightTimer.current.timeout,
                    wakeAnimation: .easeOut(duration: 0.15),
                    elapseAnimation: .easeInOut(duration: 0.6)
                )
            }
            iPlayrController.observeActivity(backlight.id, handler: wake)
            wake()
        }
    }

    private func contentView(geometry: GeometryProxy) -> some View {
        let fullWidth = geometry.size.width
        let halfWidth = fullWidth / 2

        return ZStack {
            layerView($fullScreen, width: fullWidth)
                .zIndex(1)

            splitScreenView(width: fullWidth, halfWidth: halfWidth)
                .zIndex(2)
        }
        .frame(width: fullWidth, height: Self.screenHeight)
        .clipped()
    }

    private func splitScreenView(width: CGFloat, halfWidth: CGFloat) -> some View {
        let infoPaneBinding = $infoPane
        return HStack(spacing: 0) {
            layerView($menu, width: halfWidth)
                .offset(x: isFullScreen ? -halfWidth : 0)
                .onPreferenceChange(InfoPanePreferenceKey.self) { infoPaneBinding.wrappedValue = $0 }

            RightImageView(isActive: !isFullScreen && infoPane == nil)
                .overlay {
                    if let infoPane {
                        InfoPaneView(content: infoPane)
                    }
                }
                .frame(width: halfWidth, height: Self.screenHeight)
                .clipped()
                .offset(x: isFullScreen ? halfWidth : 0)
        }
        .frame(width: width, height: Self.screenHeight)
    }

    private func layerView(_ layer: Binding<NavigationLayer>, width: CGFloat) -> some View {
        ZStack {
            ForEach(Array(layer.wrappedValue.entries.enumerated()), id: \.element.id) { index, entry in
                entry.route.destination
                    .frame(width: width, height: Self.screenHeight)
                    .offset(x: layer.wrappedValue.offset(forEntryAt: index, width: width))
                    .zIndex(Double(index))
                    .transformPreference(InfoPanePreferenceKey.self) { value in
                        if !layer.wrappedValue.isTopEntry(at: index) { value = nil }
                    }
                    .onAppear {
                        guard layer.wrappedValue.isTopEntry(at: index) else { return }
                        settle(layer)
                    }
            }
        }
        .frame(width: width, height: Self.screenHeight)
        .clipped()
    }

    private func settle(_ layer: Binding<NavigationLayer>) {
        guard layer.wrappedValue.isSettlePending else { return }
        withAnimation(Self.pushAnimation) {
            layer.wrappedValue.settle()
        } completion: {
            isNavigating = false
        }
    }

    private func handleNavigation(_ navigationType: NavigationType) {
        switch navigationType {
        case .push(let route):
            isNavigating = true
            let layer = route.isFullScreen ? $fullScreen : $menu
            layer.wrappedValue.push(route, restoreScope: iPlayrController.activeScope)

        case .pop:
            pop(isFullScreen ? $fullScreen : $menu)

        case .popToRoot:
            guard fullScreen.canPop || menu.canPop else { return }
            let restoreScope = menu.rootRestoreScope ?? fullScreen.rootRestoreScope
            withAnimation(Self.pushAnimation) {
                fullScreen.popToRoot()
                menu.popToRoot()
            } completion: {
                fullScreen.trim()
                menu.trim()
            }
            activate(restoreScope)
        }
    }

    private func pop(_ layer: Binding<NavigationLayer>) {
        guard layer.wrappedValue.canPop else { return }
        let restoreScope = layer.wrappedValue.topRestoreScope
        withAnimation(Self.pushAnimation) {
            layer.wrappedValue.pop()
        } completion: {
            layer.wrappedValue.trim()
        }
        activate(restoreScope)
    }

    private func activate(_ scope: FocusScope?) {
        guard let scope else { return }
        iPlayrController.activate(scope)
    }
}

extension View {
    func onNavigate(_ action: @escaping NavigateAction.Action) -> some View {
        environment(\.navigate, NavigateAction(action: action))
    }
}
