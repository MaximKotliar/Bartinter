import XCTest
import CoreGraphics
@testable import Bartinter

final class StatusBarGeometryTests: XCTestCase {
    func testNotchDetection() {
        XCTAssertFalse(StatusBarGeometry.hasNotchOrIsland(safeAreaTop: 20))
        XCTAssertTrue(StatusBarGeometry.hasNotchOrIsland(safeAreaTop: 47))
    }

    func testNoNotchProducesSingleFullWidthRect() {
        let rects = StatusBarGeometry.sampleRects(statusBarHeight: 20, safeAreaTop: 20,
                                                  viewWidth: 400, centerExclusionFraction: 0.42)
        XCTAssertEqual(rects.count, 1)
        XCTAssertEqual(rects[0], CGRect(x: 0, y: 0, width: 400, height: 20))
    }

    func testNotchProducesLeftAndRightRectsExcludingCenter() {
        let rects = StatusBarGeometry.sampleRects(statusBarHeight: 50, safeAreaTop: 59,
                                                  viewWidth: 400, centerExclusionFraction: 0.42)
        XCTAssertEqual(rects.count, 2)
        // side width = (1 - 0.42)/2 * 400 = 116
        XCTAssertEqual(rects[0].origin.x, 0, accuracy: 0.001)
        XCTAssertEqual(rects[0].origin.y, 0, accuracy: 0.001)
        XCTAssertEqual(rects[0].width, 116, accuracy: 0.001)
        XCTAssertEqual(rects[0].height, 50, accuracy: 0.001)
        XCTAssertEqual(rects[1].origin.x, 284, accuracy: 0.001)
        XCTAssertEqual(rects[1].origin.y, 0, accuracy: 0.001)
        XCTAssertEqual(rects[1].width, 116, accuracy: 0.001)
        XCTAssertEqual(rects[1].height, 50, accuracy: 0.001)
    }

    func testDegenerateInputsProduceNoRects() {
        XCTAssertTrue(StatusBarGeometry.sampleRects(statusBarHeight: 0, safeAreaTop: 20, viewWidth: 400, centerExclusionFraction: 0.42).isEmpty)
        XCTAssertTrue(StatusBarGeometry.sampleRects(statusBarHeight: 20, safeAreaTop: 20, viewWidth: 0, centerExclusionFraction: 0.42).isEmpty)
    }
}
