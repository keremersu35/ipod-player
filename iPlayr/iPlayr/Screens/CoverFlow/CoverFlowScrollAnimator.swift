import QuartzCore

private final class DisplayLinkProxy: NSObject {
    var callback: ((CADisplayLink) -> Void)?
    @objc func tick(_ link: CADisplayLink) { callback?(link) }
}

@MainActor
@Observable
final class CoverFlowScrollAnimator {
    private(set) var scrollOffset: CGFloat = 0
    var dragOffset: CGFloat = 0

    var visualOffset: CGFloat { scrollOffset + dragOffset }

    private let stiffness: CGFloat = 400
    private let damping: CGFloat = 30

    private var velocity: CGFloat = 0
    private var targetOffset: CGFloat = 0
    private var proxy = DisplayLinkProxy()
    private var displayLink: CADisplayLink?

    func animateTo(_ target: CGFloat) {
        targetOffset = target
        if displayLink == nil { startLink() }
    }

    func jumpTo(_ offset: CGFloat) {
        stopLink()
        scrollOffset = offset
        dragOffset = 0
        velocity = 0
        targetOffset = offset
    }

    func settle(at target: CGFloat) {
        if dragOffset != 0 { jumpTo(visualOffset) }
        animateTo(target)
    }

    private func startLink() {
        proxy.callback = { [weak self] link in self?.tick(link) }
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func tick(_ link: CADisplayLink) {
        let dt = CGFloat(link.targetTimestamp - link.timestamp)
        velocity += ((targetOffset - scrollOffset) * stiffness - velocity * damping) * dt
        scrollOffset += velocity * dt

        if abs(velocity) < 0.5 && abs(scrollOffset - targetOffset) < 0.5 {
            scrollOffset = targetOffset
            velocity = 0
            stopLink()
        }
    }
}
