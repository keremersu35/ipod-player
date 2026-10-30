import SwiftUI

@MainActor
final class WheelTracker {
    var lastAngle: CGFloat?
    var counter: CGFloat = 0

    func reset() {
        lastAngle = nil
        counter = 0
    }
}

struct iPlayrButtons: View {
    static let wheelDiameterRatio: CGFloat = 0.79
    static let glyphHeightRatio: CGFloat = 0.049

    @State private var wheel = WheelTracker()
    @Environment(iPlayrButtonController.self) private var buttonController
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width
            let buttonOffset = size * 0.32
            let glyphHeight = size * Self.wheelDiameterRatio * Self.glyphHeightRatio

            ZStack {
                Circle()
                    .fill(theme.currentTheme.wheelColor)
                    .frame(width: size * Self.wheelDiameterRatio, height: size * Self.wheelDiameterRatio)
                    .gesture(dragGesture(in: size))
                    .accessibilityLabel("Scroll wheel")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: buttonController.scrollDown()
                        case .decrement: buttonController.scrollUp()
                        @unknown default: break
                        }
                    }

                Image(theme.currentTheme.wheelInnerAppearance)
                    .resizable()
                    .brightness(theme.currentTheme.centerButtonBrightness)
                    .overlay {
                        AnodizedGrain(opacity: theme.currentTheme.grainOpacity)
                            .clipShape(Circle())
                    }
                    .frame(width: size * 0.29, height: size * 0.29)
                    .onTapGesture { buttonController.selectButtonPressed() }
                    .onLongPressGesture(minimumDuration: 0.6) { buttonController.selectLongPressed() }
                    .accessibilityLabel("Select")
                    .accessibilityAddTraits(.isButton)

                makeTextButton("MENU", glyphHeight: glyphHeight, offset: -buttonOffset,
                               onTap: { buttonController.menuButtonPressed() },
                               onLongPress: { buttonController.menuLongPressed() })
                makeIconButton(kind: .playPause, glyphHeight: glyphHeight, accessibilityLabel: "Play or pause", offsetY: buttonOffset) { buttonController.playPauseButtonPressed() }
                makeSeekButton(kind: .next, glyphHeight: glyphHeight, accessibilityLabel: "Next track", offsetX: buttonOffset,
                             onTap: { buttonController.forwardEndAltButtonPressed() },
                             onLongPressStart: { buttonController.forwardLongPressStarted() },
                             onLongPressEnd: { buttonController.forwardLongPressEnded() })
                makeSeekButton(kind: .previous, glyphHeight: glyphHeight, accessibilityLabel: "Previous track", offsetX: -buttonOffset,
                             onTap: { buttonController.backwardEndAltButtonPressed() },
                             onLongPressStart: { buttonController.backwardLongPressStarted() },
                             onLongPressEnd: { buttonController.backwardLongPressEnded() })
            }
            .frame(width: size, height: size * 0.9)
        }
    }
    
    private func dragGesture(in size: CGFloat) -> some Gesture {
        let center = size * Self.wheelDiameterRatio / 2
        return DragGesture(minimumDistance: 0)
            .onChanged { v in
                var angle = atan2(v.location.x - center, center - v.location.y) * 180 / .pi
                if angle < 0 { angle += 360 }

                guard let previousAngle = wheel.lastAngle else {
                    wheel.lastAngle = angle
                    return
                }

                var theta = previousAngle - angle
                if theta > 180 { theta -= 360 }
                if theta < -180 { theta += 360 }
                wheel.lastAngle = angle

                wheel.counter += theta

                if wheel.counter > 30 {
                    buttonController.scrollUp()
                } else if wheel.counter < -30 {
                    buttonController.scrollDown()
                }

                if abs(wheel.counter) > 30 { wheel.counter = 0 }
            }
            .onEnded { _ in
                wheel.reset()
            }
    }
    
    @ViewBuilder
    private func makeIconButton(kind: WheelGlyphKind, glyphHeight: CGFloat, accessibilityLabel: LocalizedStringKey, offsetX: CGFloat = 0, offsetY: CGFloat = 0, action: @escaping () -> Void) -> some View {
        iPlayrIconButton(kind: kind, glyphHeight: glyphHeight, accessibilityLabel: accessibilityLabel, onTapAction: action)
            .offset(x: offsetX, y: offsetY)
            .environment(theme)
    }

    @ViewBuilder
    private func makeSeekButton(kind: WheelGlyphKind, glyphHeight: CGFloat, accessibilityLabel: LocalizedStringKey, offsetX: CGFloat = 0, offsetY: CGFloat = 0,
                               onTap: @escaping () -> Void,
                               onLongPressStart: @escaping () -> Void,
                               onLongPressEnd: @escaping () -> Void) -> some View {
        iPlayrSeekButton(kind: kind, glyphHeight: glyphHeight,
                        accessibilityLabel: accessibilityLabel,
                        onTapAction: onTap,
                        onLongPressStart: onLongPressStart,
                        onLongPressEnd: onLongPressEnd)
            .offset(x: offsetX, y: offsetY)
            .environment(theme)
    }

    @ViewBuilder
    private func makeTextButton(_ text: LocalizedStringKey, glyphHeight: CGFloat, offset: CGFloat,
                                onTap: @escaping () -> Void,
                                onLongPress: @escaping () -> Void) -> some View {
        Text(text)
            .font(.system(size: glyphHeight * 1.3, weight: .bold))
            .foregroundColor(theme.currentTheme.wheelIconTint)
            .padding(20)
            .contentShape(Rectangle())
            .offset(y: offset)
            .onTapGesture(perform: onTap)
            .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50, perform: onLongPress)
            .accessibilityLabel(text)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Main menu", onLongPress)
    }
}

struct iPlayrIconButton: View {
    let kind: WheelGlyphKind
    let glyphHeight: CGFloat
    let accessibilityLabel: LocalizedStringKey
    let onTapAction: () -> Void
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        WheelGlyph(kind: kind)
            .fill(theme.currentTheme.wheelIconTint)
            .frame(width: glyphHeight * kind.aspectRatio, height: glyphHeight)
            .padding(20)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTapAction)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
    }
}

struct iPlayrSeekButton: View {
    let kind: WheelGlyphKind
    let glyphHeight: CGFloat
    let accessibilityLabel: LocalizedStringKey
    let onTapAction: () -> Void
    let onLongPressStart: () -> Void
    let onLongPressEnd: () -> Void
    @Environment(ThemeManager.self) private var theme
    @State private var isPressed: Bool = false

    var body: some View {
        WheelGlyph(kind: kind)
            .fill(theme.currentTheme.wheelIconTint)
            .frame(width: glyphHeight * kind.aspectRatio, height: glyphHeight)
            .padding(20)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .onTapGesture(perform: onTapAction)
            .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50) {
                onLongPressStart()
            } onPressingChanged: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
                if !pressing {
                    onLongPressEnd()
                }
            }
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
    }
}

