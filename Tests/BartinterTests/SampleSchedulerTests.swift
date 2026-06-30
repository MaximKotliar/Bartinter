import XCTest
import UIKit
@testable import Bartinter

@MainActor
final class SampleSchedulerTests: XCTestCase {
    func testStartsParked() {
        let s = SampleScheduler(maxSampleRate: 10, onSample: {})
        XCTAssertTrue(s.isParked)
    }

    func testSetNeedsSampleUnparks() {
        let s = SampleScheduler(maxSampleRate: 10, onSample: {})
        s.setNeedsSample()
        XCTAssertFalse(s.isParked)
    }

    func testTickSamplesThenParks() {
        var count = 0
        let s = SampleScheduler(maxSampleRate: 10, onSample: { count += 1 })
        s.setNeedsSample()
        s.handleTick(now: 0)
        XCTAssertEqual(count, 1)
        XCTAssertTrue(s.isParked) // nothing re-marked -> parks
    }

    func testThrottleWithinInterval() {
        var count = 0
        let s = SampleScheduler(maxSampleRate: 10, onSample: { count += 1 }) // interval 0.1
        s.setNeedsSample(); s.handleTick(now: 0)          // sample #1
        s.setNeedsSample(); s.handleTick(now: 0.05)        // too soon
        XCTAssertEqual(count, 1)
        s.handleTick(now: 0.1)                             // sample #2
        XCTAssertEqual(count, 2)
    }

    func testInactiveDoesNotSample() {
        var count = 0
        let s = SampleScheduler(maxSampleRate: 10, onSample: { count += 1 })
        s.isActive = false
        s.setNeedsSample()
        s.handleTick(now: 0)
        XCTAssertEqual(count, 0)
        XCTAssertTrue(s.isParked)
    }

    func testScrollObservationMarksDirty() {
        let s = SampleScheduler(maxSampleRate: 10, onSample: {})
        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        scrollView.contentSize = CGSize(width: 100, height: 1000)
        s.observe(scrollView)
        scrollView.contentOffset = CGPoint(x: 0, y: 50)
        XCTAssertFalse(s.isParked)
    }
}
