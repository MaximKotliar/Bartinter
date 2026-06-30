import UIKit
import QuartzCore

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

    init(maxSampleRate: Double, onSample: @escaping () -> Void) {
        self.minInterval = maxSampleRate > 0 ? 1.0 / maxSampleRate : 0
        self.onSample = onSample
    }

    func start() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick))
        link.isPaused = isParked
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    func setNeedsSample() {
        dirty = true
        isParked = false
        displayLink?.isPaused = false
    }

    func observe(_ scrollView: UIScrollView) {
        observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.setNeedsSample() }
        }
    }

    @objc private func tick(_ link: CADisplayLink) {
        handleTick(now: link.timestamp)
        link.isPaused = isParked
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
