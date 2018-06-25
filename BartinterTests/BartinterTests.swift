//
//  BartinterTests.swift
//  BartinterTests
//
//  Created by Maxim Kotliar on 6/25/18.
//  Copyright © 2018 Maxim Kotliar. All rights reserved.
//

@testable import Bartinter
import XCTest

class BartinterTests: XCTestCase {

    func testSwizzling() {
        func noSwizzlingTest() {
            Bartinter.isSwizzlingEnabled = false

            let selectorA = #selector(getter: UIViewController.childViewControllerForStatusBarStyle)
            let swizzledSelectorA = #selector(getter: UIViewController.swizzledChildViewControllerForStatusBarStyle)
            let selectorB = #selector(UIView.layoutSubviews)
            let swizzledSelectorB = #selector(UIView.swizzledLayoutSubviews)

            let swizzledImplementationA = class_getMethodImplementation(UIViewController.self,
                                                                        swizzledSelectorA)!
            let swizzledImplementationB = class_getMethodImplementation(UIView.self,
                                                                        swizzledSelectorB)!

            // Perform swizzling
            let controller = UIViewController()
            controller.updatesStatusBarAppearanceAutomatically = true
            let currentImplementationA = class_getMethodImplementation(UIViewController.self,
                                                                       selectorA)!
            let currentImplementationB = class_getMethodImplementation(UIView.self,
                                                                       selectorB)!
            XCTAssert(currentImplementationA != swizzledImplementationA)
            XCTAssert(currentImplementationB != swizzledImplementationB)
        }

        func swizzlingTest() {
            Bartinter.isSwizzlingEnabled = true

            let selectorA = #selector(getter: UIViewController.childViewControllerForStatusBarStyle)
            let swizzledSelectorA = #selector(getter: UIViewController.swizzledChildViewControllerForStatusBarStyle)
            let selectorB = #selector(UIView.layoutSubviews)
            let swizzledSelectorB = #selector(UIView.swizzledLayoutSubviews)

            let swizzledImplementationA = class_getMethodImplementation(UIViewController.self,
                                                                        swizzledSelectorA)!
            let swizzledImplementationB = class_getMethodImplementation(UIView.self,
                                                                        swizzledSelectorB)!

            // Perform swizzling
            let controller = UIViewController()
            controller.updatesStatusBarAppearanceAutomatically = true
            let currentImplementationA = class_getMethodImplementation(UIViewController.self,
                                                                       selectorA)!
            let currentImplementationB = class_getMethodImplementation(UIView.self,
                                                                       selectorB)!
            XCTAssert(currentImplementationA == swizzledImplementationA)
            XCTAssert(currentImplementationB == swizzledImplementationB)
        }

        noSwizzlingTest()
        swizzlingTest()
    }

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
