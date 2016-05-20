//
//  NewAccountSetupUITest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

import XCTest
import pEpForiOS

class NewAccountSetupUITest: XCTestCase {
    override func setUp() {
        super.setUp()

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

    func testNewAccountSimple() {
        // TODO: Use TestData
        let imapPassword = "uiae"
        let imapServer = "uiae"
        let smtpServer = "uiae"
        let email = "some@email"

        let tablesQuery = XCUIApplication().tables

        // TODO: Is using the accessibility identifier a better idea?
        let tf1 = tablesQuery.cells.secureTextFields["Password"]
        tf1.tap()
        tf1.typeText("WRONG!")

        let tf2 = tablesQuery.cells.textFields["Email"]
        tf2.tap()
        tf2.typeText(email)
        XCUIApplication().navigationBars.buttons["Next"].tap()

        let tf3 = tablesQuery.textFields["IMAP Server"]
        tf3.tap()
        tf3.typeText(imapServer)
        XCUIApplication().navigationBars.buttons["Next"].tap()

        let tf4 = tablesQuery.textFields["SMTP Server"]
        tf4.tap()
        tf4.typeText(smtpServer)
        XCUIApplication().navigationBars.buttons["Next"].tap()

        /*
        expectationWithDescription("Never happens")
        waitForExpectationsWithTimeout(3000, handler: nil)
         */
    }
}