import UIKit

/// A type that can asynchronously compute the average luminance of a set of
/// rectangular regions within a `CALayer`.
///
/// Conforming types deliver the result on the main actor via `completion`.
/// A `nil` result indicates that luminance could not be determined (e.g. no
/// Metal device available, all rects are empty, or the capture produced no output).
@MainActor
protocol LuminanceSampling: AnyObject {
    func sampleLuminance(
        of layer: CALayer,
        rects: [CGRect],
        completion: @escaping @MainActor (CGFloat?) -> Void
    )
}

/// `RegionCapture`'s existing `sampleLuminance(of:rects:completion:)` method
/// already matches this signature exactly — no modifications to `RegionCapture` required.
extension RegionCapture: LuminanceSampling {}
