//
//  BartinterUITests.swift
//  BartinterUITests
//
//  Created by Maxim Kotliar on 6/25/18.
//  Copyright © 2018 Maxim Kotliar. All rights reserved.
//

import XCTest

class BartinterUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    func testExample() {
        let app = XCUIApplication()
        let changeColorButton = app.buttons["CHANGE COLOR"]
        var isDark: Bool {
            return XCUIApplication().staticTexts["dark"].exists
        }
        var isLight: Bool {
            return XCUIApplication().staticTexts["light"].exists
        }
        changeColorButton.tap()
        XCTAssert(isDark)
        changeColorButton.tap()
        XCTAssert(isDark)
        changeColorButton.tap()
        XCTAssert(isDark)
        changeColorButton.tap()
        XCTAssert(isLight)
        changeColorButton.tap()
        XCTAssert(isLight)
        changeColorButton.tap()
        XCTAssert(isDark)
    }
    
}
