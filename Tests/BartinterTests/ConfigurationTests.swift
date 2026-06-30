import XCTest
import UIKit
@testable import Bartinter

@MainActor
final class ConfigurationTests: XCTestCase {
    func testDefaults() {
        let c = Bartinter.Configuration()
        XCTAssertEqual(c.animationDuration, 0.2)
        XCTAssertEqual(c.animationType, .fade)
        XCTAssertEqual(c.midPoint, 0.6, accuracy: 0.0001)
        XCTAssertEqual(c.antiFlickRange, 0.08, accuracy: 0.0001)
        XCTAssertEqual(c.maxSampleRate, 12)
    }

    func testSharedDefaultIsMutable() {
        Bartinter.Configuration.default.midPoint = 0.5
        XCTAssertEqual(Bartinter.Configuration.default.midPoint, 0.5, accuracy: 0.0001)
        Bartinter.Configuration.default = Bartinter.Configuration() // reset for other tests
    }
}
