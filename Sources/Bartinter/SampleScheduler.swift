import UIKit
import QuartzCore

@MainActor
private final class DisplayLinkProxy: NSObject {
    weak var scheduler: SampleScheduler?
    init(_ scheduler: SampleScheduler) { self.scheduler = scheduler }
    @objc func tick(_ link: CADisplayLink) {
        // CADisplayLink added to .main always fires on the main run loop.
        scheduler?.handleDisplayLink(timestamp: link.timestamp)
    }
}

@MainActor
final class SampleScheduler {
    var isActive = true
    private(set) var isParked = true

    private let minInterval: CFTimeInterval
    private let onSample: () -> Void
    private var dirty = false
    private var lastSampleTime: CFTimeInterval = -.infinity
    private var displayLink: CADisplayLink?
    private var observation: NSKeyValueObservation?
    private var proxy: DisplayLinkProxy?

    init(maxSampleRate: Double, onSample: @escaping () -> Void) {
        self.minInterval = maxSampleRate > 0 ? 1.0 / maxSampleRate : 0
        self.onSample = onSample
    }

    isolated deinit { displayLink?.invalidate() }

    func start() {
        guard displayLink == nil else { return }
        let proxy = DisplayLinkProxy(self)
        self.proxy = proxy
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.tick(_:)))
        link.isPaused = isParked
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        proxy = nil
    }

    func setNeedsSample() {
        dirty = true
        isParked = false
        displayLink?.isPaused = false
    }

    func observe(_ scrollView: UIScrollView) {
        observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
            if Thread.isMainThread {
                MainActor.assumeIsolated { self?.setNeedsSample() }
            } else {
                Task { @MainActor [weak self] in self?.setNeedsSample() }
            }
        }
    }

    func handleDisplayLink(timestamp: CFTimeInterval) {
        handleTick(now: timestamp)
        displayLink?.isPaused = isParked
    }

    /// Core state machine, separated from CADisplayLink for deterministic testing.
    func handleTick(now: CFTimeInterval) {
        guard isActive, dirty else { isParked = true; return }
        guard now - lastSampleTime >= minInterval else { return }
        dirty = false
        lastSampleTime = now
        onSample()
        if !dirty { isParked = true }
    }
}
