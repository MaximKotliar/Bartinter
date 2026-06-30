import UIKit

enum LuminanceMath {
    /// WCAG sRGB transfer: gamma-encoded component (0...1) -> linear.
    static func linearize(_ c: CGFloat) -> CGFloat {
        c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    /// Rec.709 relative luminance from sRGB-encoded components (0...1).
    static func relativeLuminance(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
        0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
    }

    /// Decide status bar style with an anti-flicker hysteresis band around `midPoint`.
    static func style(forLuminance luminance: CGFloat,
                      midPoint: CGFloat,
                      antiFlickRange: CGFloat,
                      current: UIStatusBarStyle) -> UIStatusBarStyle {
        let half = antiFlickRange / 2
        if luminance <= midPoint - half { return .lightContent } // dark bg -> white text
        if luminance >= midPoint + half { return .darkContent }  // light bg -> dark text
        return current
    }
}
