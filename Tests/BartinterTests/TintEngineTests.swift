import XCTest
import UIKit
@testable import Bartinter

@MainActor
final class TintEngineTests: XCTestCase {
    /// Stub that returns a canned luminance synchronously.
    private final class StubSampler: LuminanceSampling {
        var value: CGFloat?
        init(_ value: CGFloat?) { self.value = value }
        func sampleLuminance(
            of layer: CALayer,
            rects: [CGRect],
            completion: @escaping @MainActor (CGFloat?) -> Void
        ) {
            completion(value)
        }
    }

    private func engine(
        _ luminance: CGFloat?,
        onChange: @escaping (UIStatusBarStyle) -> Void
    ) -> TintEngine {
        TintEngine(
            configuration: Bartinter.Configuration(),
            sampler: StubSampler(luminance),
            onStyleChange: onChange
        )
    }

    func testDarkBackgroundEmitsLightContent() {
        var emitted: UIStatusBarStyle?
        let e = engine(0.1) { emitted = $0 }
        e.sample(layer: CALayer(), statusBarHeight: 44, safeAreaTop: 20, viewWidth: 400)
        XCTAssertEqual(emitted, .lightContent)
        XCTAssertEqual(e.currentStyle, .lightContent)
    }

    func testLightBackgroundEmitsDarkContent() {
        var emitted: UIStatusBarStyle?
        let e = engine(0.95) { emitted = $0 }
        e.sample(layer: CALayer(), statusBarHeight: 44, safeAreaTop: 20, viewWidth: 400)
        XCTAssertEqual(emitted, .darkContent)
    }

    func testNoChangeDoesNotEmit() {
        var calls = 0
        let e = engine(0.1) { _ in calls += 1 }
        e.sample(layer: CALayer(), statusBarHeight: 44, safeAreaTop: 20, viewWidth: 400) // -> .lightContent, emit
        e.sample(layer: CALayer(), statusBarHeight: 44, safeAreaTop: 20, viewWidth: 400) // -> .lightContent, no emit
        XCTAssertEqual(calls, 1)
    }

    func testNoRectsDoesNotEmit() {
        var calls = 0
        let e = engine(0.1) { _ in calls += 1 }
        e.sample(layer: CALayer(), statusBarHeight: 0, safeAreaTop: 20, viewWidth: 0)
        XCTAssertEqual(calls, 0)
    }

    func testNilLuminanceDoesNotEmit() {
        var calls = 0
        let e = engine(nil) { _ in calls += 1 }
        e.sample(layer: CALayer(), statusBarHeight: 44, safeAreaTop: 20, viewWidth: 400)
        XCTAssertEqual(calls, 0)
    }

    func testHysteresisBandDoesNotEmitWithMutableStub() {
        // Use a mutable stub to drive two samples.
        final class MutableStub: LuminanceSampling {
            var value: CGFloat = 0.1
            func sampleLuminance(
                of layer: CALayer,
                rects: [CGRect],
                completion: @escaping @MainActor (CGFloat?) -> Void
            ) { completion(value) }
        }
        let stub = MutableStub()
        var calls = 0
        let e = TintEngine(
            configuration: Bartinter.Configuration(),
            sampler: stub,
            onStyleChange: { _ in calls += 1 }
        )
        // First sample: dark (0.1) → .lightContent, emit once
        e.sample(layer: CALayer(), statusBarHeight: 44, safeAreaTop: 20, viewWidth: 400)
        XCTAssertEqual(calls, 1)

        // Second sample: in-band (0.60) → LuminanceMath returns current (.lightContent) → no emit
        stub.value = 0.60
        e.sample(layer: CALayer(), statusBarHeight: 44, safeAreaTop: 20, viewWidth: 400)
        XCTAssertEqual(calls, 1, "In-band luminance should not trigger a style change")
        XCTAssertEqual(e.currentStyle, .lightContent)
    }
}
