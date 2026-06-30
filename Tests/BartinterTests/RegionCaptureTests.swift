import XCTest
import CoreImage
import UIKit
@testable import Bartinter

final class RegionCaptureTests: XCTestCase {
    private func solid(_ color: CIColor) -> CIImage {
        CIImage(color: color).cropped(to: CGRect(x: 0, y: 0, width: 8, height: 8))
    }

    func testAverageLuminanceWhite() {
        let l = RegionCapture.averageLuminance(of: solid(CIColor(red: 1, green: 1, blue: 1)),
                                               context: RegionCapture.sharedContext)
        XCTAssertEqual(l ?? -1, 1.0, accuracy: 0.05)
    }

    func testAverageLuminanceBlack() {
        let l = RegionCapture.averageLuminance(of: solid(CIColor(red: 0, green: 0, blue: 0)),
                                               context: RegionCapture.sharedContext)
        XCTAssertEqual(l ?? -1, 0.0, accuracy: 0.05)
    }

    func testAverageLuminanceMidGrayBelowHalf() {
        let l = RegionCapture.averageLuminance(of: solid(CIColor(red: 0.5, green: 0.5, blue: 0.5)),
                                               context: RegionCapture.sharedContext) ?? -1
        XCTAssertGreaterThan(l, 0.1)
        XCTAssertLessThan(l, 0.35) // linearized mid-gray ~0.21
    }
}
