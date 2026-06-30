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

@MainActor
final class RegionCaptureCARendererTests: XCTestCase {
    func testCapturesSolidRedLayerLuminance() throws {
        guard let capture = RegionCapture() else { throw XCTSkip("No Metal device") }
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: 0, width: 200, height: 60)
        layer.backgroundColor = UIColor.red.cgColor

        let exp = expectation(description: "luminance")
        var result: CGFloat?
        capture.sampleLuminance(of: layer, rects: [layer.bounds]) { value in
            result = value
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
        XCTAssertEqual(result ?? -1, 0.2126, accuracy: 0.1) // red
    }
}
