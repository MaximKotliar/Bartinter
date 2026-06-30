import XCTest
import SwiftUI
@testable import Bartinter

@MainActor
final class TintsStatusBarTests: XCTestCase {
    func testInstallerIsSafeNoOpWithoutScene() {
        let root = UIViewController()
        let installer = _BartinterInstaller(configuration: .init(), isActive: true)
        root.addChild(installer)
        installer.didMove(toParent: root)

        // With no window/scene attached, installIfPossible() must be a safe, repeatable no-op.
        installer.installIfPossible()
        installer.installIfPossible()

        XCTAssertNil(installer.view.window)              // precondition genuinely holds
        XCTAssertEqual(root.children.count, 1)           // nothing was wrapped/added
        XCTAssertTrue(root.children.contains(installer)) // installer still attached, not restructured
    }
}
