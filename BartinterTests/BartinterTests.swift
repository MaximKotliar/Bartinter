//
//  BartinterTests.swift
//  BartinterTests
//
//  Created by Maxim Kotliar on 6/25/18.
//  Copyright © 2018 Maxim Kotliar. All rights reserved.
//

import Bartinter
import XCTest

class BartinterTests: XCTestCase {

    weak var bartinter: UIViewController?
    func testDeallocation() {
        Bartinter.isSwizzlingEnabled = false
        let expectation = self.expectation(description: "deallocated")
        DispatchQueue.main.async {
            let controller = UIViewController()
            controller.loadViewIfNeeded()
            XCTAssert(controller.statusBarUpdater == nil)
            controller.updatesStatusBarAppearanceAutomatically = true
            XCTAssert(controller.statusBarUpdater != nil)
            self.bartinter = controller.statusBarUpdater
            controller.updatesStatusBarAppearanceAutomatically = false
            XCTAssert(controller.statusBarUpdater == nil)
            controller.updatesStatusBarAppearanceAutomatically = true
            XCTAssert(controller.statusBarUpdater != nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1.0) { _ in
            XCTAssert(self.bartinter == nil)
        }
    }
}
