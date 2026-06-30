import XCTest
import UIKit
@testable import Bartinter

final class LuminanceMathTests: XCTestCase {
    func testRelativeLuminanceEndpoints() {
        XCTAssertEqual(LuminanceMath.relativeLuminance(r: 1, g: 1, b: 1), 1.0, accuracy: 0.001)
        XCTAssertEqual(LuminanceMath.relativeLuminance(r: 0, g: 0, b: 0), 0.0, accuracy: 0.001)
    }

    func testRelativeLuminanceRedUsesRec709Weight() {
        // pure sRGB red -> linearize(1)=1 -> 0.2126
        XCTAssertEqual(LuminanceMath.relativeLuminance(r: 1, g: 0, b: 0), 0.2126, accuracy: 0.01)
    }

    func testDarkBackgroundPicksLightContent() {
        let style = LuminanceMath.style(forLuminance: 0.1, midPoint: 0.6, antiFlickRange: 0.08, current: .darkContent)
        XCTAssertEqual(style, .lightContent)
    }

    func testLightBackgroundPicksDarkContent() {
        let style = LuminanceMath.style(forLuminance: 0.9, midPoint: 0.6, antiFlickRange: 0.08, current: .lightContent)
        XCTAssertEqual(style, .darkContent)
    }

    func testWithinHysteresisBandHoldsCurrent() {
        // band = [0.56, 0.64]; 0.6 holds whatever was current
        XCTAssertEqual(LuminanceMath.style(forLuminance: 0.6, midPoint: 0.6, antiFlickRange: 0.08, current: .lightContent), .lightContent)
        XCTAssertEqual(LuminanceMath.style(forLuminance: 0.6, midPoint: 0.6, antiFlickRange: 0.08, current: .darkContent), .darkContent)
    }
}
