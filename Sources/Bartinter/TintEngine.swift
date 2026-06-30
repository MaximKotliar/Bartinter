import UIKit

/// Orchestrates the sampling → decision → emission pipeline on the main actor.
///
/// On each call to `sample(layer:statusBarHeight:safeAreaTop:viewWidth:)`:
/// 1. `StatusBarGeometry.sampleRects` derives the regions to capture.
/// 2. The injected `LuminanceSampling` sampler captures the average luminance.
/// 3. `LuminanceMath.style(forLuminance:midPoint:antiFlickRange:current:)` decides
///    the new `UIStatusBarStyle` with hysteresis.
/// 4. `onStyleChange` fires only when the decided style differs from `currentStyle`.
@MainActor
final class TintEngine {
    // MARK: - Public interface

    var configuration: Bartinter.Configuration

    /// The most-recently emitted style. Returns `.darkContent` until the first
    /// luminance sample arrives and a style has been decided.
    var currentStyle: UIStatusBarStyle { _currentStyle ?? .darkContent }

    // MARK: - Private state

    private let sampler: LuminanceSampling
    private let onStyleChange: (UIStatusBarStyle) -> Void

    /// `nil` until the first luminance reading arrives. Using `nil` as the sentinel
    /// lets the engine emit on the very first sample regardless of direction, so
    /// callers always receive an initial style rather than potentially missing the
    /// first frame if the background matches the `.darkContent` default.
    private var _currentStyle: UIStatusBarStyle?

    // MARK: - Init

    init(
        configuration: Bartinter.Configuration,
        sampler: LuminanceSampling,
        onStyleChange: @escaping (UIStatusBarStyle) -> Void
    ) {
        self.configuration = configuration
        self.sampler = sampler
        self.onStyleChange = onStyleChange
    }

    // MARK: - Sampling

    /// Captures the status-bar region of `layer` and emits a style change when
    /// the luminance decision crosses outside the hysteresis band.
    func sample(
        layer: CALayer,
        statusBarHeight: CGFloat,
        safeAreaTop: CGFloat,
        viewWidth: CGFloat
    ) {
        let rects = StatusBarGeometry.sampleRects(
            statusBarHeight: statusBarHeight,
            safeAreaTop: safeAreaTop,
            viewWidth: viewWidth
        )
        guard !rects.isEmpty else { return }

        // Capture config before the async hop so mutations during flight don't affect
        // the in-flight decision.
        let config = configuration

        sampler.sampleLuminance(of: layer, rects: rects) { [weak self] luminance in
            guard let self, let luminance else { return }
            let newStyle = LuminanceMath.style(
                forLuminance: luminance,
                midPoint: config.midPoint,
                antiFlickRange: config.antiFlickRange,
                current: self._currentStyle ?? .darkContent
            )
            // Emit on first sample unconditionally, then only on style changes.
            guard newStyle != self._currentStyle else { return }
            self._currentStyle = newStyle
            self.onStyleChange(newStyle)
        }
    }
}
