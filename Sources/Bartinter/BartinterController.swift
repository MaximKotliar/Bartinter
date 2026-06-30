import UIKit

/// Per-screen controller that owns `preferredStatusBarStyle` and wires together
/// `SampleScheduler`, `TintEngine`, `StatusBarGeometry`, and a `LuminanceSampling`
/// implementation (GPU-backed `RegionCapture` or `NullSampler` fallback).
///
/// Typical use:
/// ```swift
/// let bartinter = BartinterController()
/// addChild(bartinter)
/// bartinter.tint(self)   // start sampling; `self.childForStatusBarStyle` must return bartinter
/// ```
public final class BartinterController: UIViewController {

    // MARK: - Public interface

    /// Controls whether sampling is active. Setting to `false` pauses the display link.
    /// Setting back to `true` immediately marks a sample as needed.
    public var isActive: Bool {
        get { scheduler.isActive }
        set {
            scheduler.isActive = newValue
            if newValue { scheduler.setNeedsSample() }
        }
    }

    /// The style most recently decided by the engine. `.darkContent` until the
    /// first sample arrives (mirrors `TintEngine.currentStyle`'s sentinel default).
    public var currentStyle: UIStatusBarStyle { engine.currentStyle }

    // MARK: - UIViewController overrides

    public override var preferredStatusBarStyle: UIStatusBarStyle { style }

    public override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        configuration.animationType
    }

    // MARK: - Private state

    /// Mirrors `engine.currentStyle`; updated only when a style change is emitted
    /// so `preferredStatusBarStyle` is stable between samples.
    private var style: UIStatusBarStyle = .darkContent

    private let configuration: Bartinter.Configuration
    private weak var host: UIViewController?

    // IUOs: fully assigned before any external caller can reach them (the only
    // path to engine/scheduler is via public methods, all of which require
    // `tint(_:)` to have been called first, which happens after init returns).
    private var engine: TintEngine!
    private var scheduler: SampleScheduler!

    // MARK: - Init

    /// Convenience initialiser for app code. Uses GPU-backed `RegionCapture` when a
    /// Metal device is available; falls back to `NullSampler` on devices without Metal.
    public convenience init(configuration: Bartinter.Configuration = .default) {
        let sampler: LuminanceSampling = RegionCapture() ?? RegionCapture.disabled
        self.init(configuration: configuration, sampler: sampler)
    }

    /// Designated initialiser — `internal` so tests can inject a stub sampler.
    init(configuration: Bartinter.Configuration, sampler: LuminanceSampling) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)

        // Both closures capture `self` weakly; the engine fires `applyStyleChange`
        // on the main actor when the decided style changes.
        engine = TintEngine(
            configuration: configuration,
            sampler: sampler
        ) { [weak self] newStyle in
            self?.applyStyleChange(newStyle)
        }

        scheduler = SampleScheduler(
            maxSampleRate: configuration.maxSampleRate
        ) { [weak self] in
            self?.performSample()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    // MARK: - View lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.isHidden = true
        view.frame = .zero
    }

    // MARK: - Public API

    /// Registers `host` as the view controller whose status bar appearance this
    /// controller manages, then starts the display-link-backed scheduler.
    ///
    /// The caller must implement `childForStatusBarStyle` to return this controller,
    /// so that UIKit routes status-bar queries here.
    public func tint(_ host: UIViewController) {
        self.host = host
        scheduler.start()
        scheduler.setNeedsSample()
    }

    /// Registers a scroll view whose `contentOffset` changes trigger re-sampling.
    public func observe(_ scrollView: UIScrollView) {
        scheduler.observe(scrollView)
    }

    /// Forces a sample on the next display-link tick.
    public func setNeedsStatusBarTintUpdate() {
        scheduler.setNeedsSample()
    }

    /// Executes a luminance sample immediately, bypassing the display link.
    ///
    /// - Note: Internal; intended for unit tests and programmatic triggering.
    ///   When the injected sampler delivers results synchronously (e.g. a stub),
    ///   `currentStyle` and `preferredStatusBarStyle` are updated before this returns.
    func performSample() {
        guard let host else { return }
        let hostView = host.view!
        let width = hostView.bounds.width
        let safeAreaTop = hostView.safeAreaInsets.top
        // Prefer the live status-bar frame height from the window scene; fall back
        // to the safe-area top inset (or 44 pt on full-screen layout without insets).
        let statusBarHeight =
            hostView.window?.windowScene?.statusBarManager?.statusBarFrame.height
            ?? max(safeAreaTop, 44)
        engine.sample(
            layer: hostView.layer,
            statusBarHeight: statusBarHeight,
            safeAreaTop: safeAreaTop,
            viewWidth: width
        )
    }

    // MARK: - Private helpers

    private func applyStyleChange(_ newStyle: UIStatusBarStyle) {
        guard style != newStyle else { return }
        style = newStyle
        UIView.animate(withDuration: configuration.animationDuration) { [weak self] in
            self?.host?.setNeedsStatusBarAppearanceUpdate()
        }
    }
}
