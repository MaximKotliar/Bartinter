import XCTest
import UIKit
@testable import Bartinter

@MainActor
final class BartinterControllerTests: XCTestCase {
    private final class StubSampler: LuminanceSampling {
        var value: CGFloat?
        init(_ v: CGFloat?) { value = v }
        func sampleLuminance(
            of layer: CALayer,
            rects: [CGRect],
            completion: @escaping @MainActor (CGFloat?) -> Void
        ) {
            completion(value)
        }
    }

    func testPerformSampleUpdatesStyleAndPreferredStyle() {
        let host = UIViewController()
        host.view.frame = CGRect(x: 0, y: 0, width: 400, height: 800)
        let controller = BartinterController(configuration: .init(), sampler: StubSampler(0.05))
        host.addChild(controller)
        controller.tint(host)
        controller.performSample()
        XCTAssertEqual(controller.currentStyle, .lightContent)
        XCTAssertEqual(controller.preferredStatusBarStyle, .lightContent)
    }
}
