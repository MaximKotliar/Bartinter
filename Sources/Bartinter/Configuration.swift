import UIKit

extension Bartinter {
    public struct Configuration: Sendable {
        public var animationDuration: TimeInterval
        public var animationType: UIStatusBarAnimation
        public var midPoint: CGFloat
        public var antiFlickRange: CGFloat
        public var maxSampleRate: Double

        public init(animationDuration: TimeInterval = 0.2,
                    animationType: UIStatusBarAnimation = .fade,
                    midPoint: CGFloat = 0.6,
                    antiFlickRange: CGFloat = 0.08,
                    maxSampleRate: Double = 12) {
            self.animationDuration = animationDuration
            self.animationType = animationType
            self.midPoint = midPoint
            self.antiFlickRange = antiFlickRange
            self.maxSampleRate = maxSampleRate
        }
    }
}

extension Bartinter.Configuration {
    /// App-wide defaults, set once at launch on the main actor.
    @MainActor public static var `default` = Bartinter.Configuration()
}
