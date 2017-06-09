//
//  HandshakeUITest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 09.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

class HandshakeUITest: XCTestCase {
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
    
    func testHandshake() {
        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.cells.staticTexts["oh yeah, subject"].tap()
        let handshakeButton = app.toolbars.buttons["p≡p"]

        while true {
            handshakeButton.tap()

            let navBar = app.navigationBars["Inbox"]
            let navButtons = navBar.children(matching: .button)
            let backButton = navButtons.matching(identifier: "Back").element(boundBy: 0)

            let stopTrustButton = tablesQuery.buttons["Stop Trusting"]
            let startTrustButton = tablesQuery.buttons["Start Trusting"]

            if stopTrustButton.exists {
                stopTrustButton.tap()
                tablesQuery.buttons["Wrong"].tap()
                backButton.tap()
            } else if startTrustButton.exists {
                startTrustButton.tap()
                tablesQuery.buttons["Confirm"].tap()
                backButton.tap()
            } else {
                tablesQuery.buttons["Confirm"].tap()
                backButton.tap()
            }
        }
    }
}
