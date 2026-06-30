import CoreGraphics

enum StatusBarGeometry {
    /// Heuristic: notch/Dynamic Island devices have a top safe-area inset well above the
    /// classic 20pt status bar.
    static func hasNotchOrIsland(safeAreaTop: CGFloat) -> Bool { safeAreaTop > 24 }

    /// Sampling rects for the status-bar strip. On notch/island devices the central band
    /// (where the cutout sits) is excluded and the readable left/right regions are returned.
    static func sampleRects(statusBarHeight: CGFloat,
                            safeAreaTop: CGFloat,
                            viewWidth: CGFloat,
                            centerExclusionFraction: CGFloat = 0.42) -> [CGRect] {
        guard statusBarHeight > 0, viewWidth > 0 else { return [] }
        guard hasNotchOrIsland(safeAreaTop: safeAreaTop) else {
            return [CGRect(x: 0, y: 0, width: viewWidth, height: statusBarHeight)]
        }
        let sideWidth = (1 - centerExclusionFraction) / 2 * viewWidth
        guard sideWidth > 0 else { return [] }
        return [
            CGRect(x: 0, y: 0, width: sideWidth, height: statusBarHeight),
            CGRect(x: viewWidth - sideWidth, y: 0, width: sideWidth, height: statusBarHeight)
        ]
    }
}
