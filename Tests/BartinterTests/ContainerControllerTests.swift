import XCTest
import UIKit
@testable import Bartinter

@MainActor
final class ContainerControllerTests: XCTestCase {
    func testContainerEmbedsContentAndForwardsStatusBarChild() {
        let content = UIViewController()
        content.view.backgroundColor = .black
        let container = BartinterContainerController(content: content, configuration: .init())
        container.view.frame = CGRect(x: 0, y: 0, width: 400, height: 800)
        container.loadViewIfNeeded()

        XCTAssertIdentical(container.childForStatusBarStyle, container.bartinter)
        XCTAssertTrue(container.children.contains(content))
        XCTAssertEqual(content.view.frame, container.view.bounds)
    }
}
