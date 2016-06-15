//
//  SomeDebugUITest.swift
//  pEpForiOS
//
//  Created by ana on 23/5/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

class DebugUITest: XCTestCase {
    
    override func setUp() {
        super.setUp()
       
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func waitForever() {
        expectationWithDescription("Never happens")
        waitForExpectationsWithTimeout(3000, handler: nil)
    }

    func testExample() {
        
        let app = XCUIApplication()
        let tablesQuery = app.tables
        let moreNumbersKey = tablesQuery.textFields["email"]
        moreNumbersKey.typeText("asd2@as")

        moreNumbersKey.tap()

        
        let passwordSecureTextField = tablesQuery.secureTextFields["password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("asd2")

        app.navigationBars["pEpForiOS.UserInfoTableView"].buttons["Next"].tap()
        waitForever()
    }

}
