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

    /*
     Use if you want to wait forever. May be useful for debugging.
     */
    func waitForever() {
        expectationWithDescription("Never happens")
        waitForExpectationsWithTimeout(3000, handler: nil)
    }

    func clearTextField(textField: XCUIElement) {
        guard let _ = textField.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }
        while (textField.value as? String)?.characters.count > 0 {
            textField.typeText("\u{8}")
        }
    }

    func testNewAccountThatShouldFail() {
        let imapServer = "uiae"
        let smtpServer = "uiae"
        let email = "some@email"

        let tablesQuery = XCUIApplication().tables

        var tf = tablesQuery.cells.textFields["email"]
        tf.typeText(email)

        tf = tablesQuery.cells.secureTextFields["password"]
        tf.tap()
        tf.typeText("WRONG!")

        XCUIApplication().navigationBars.buttons["Next"].tap()

        tf = tablesQuery.textFields["imapServer"]
        tf.typeText(imapServer)
        XCUIApplication().navigationBars.buttons["Next"].tap()

        tf = tablesQuery.textFields["smtpServer"]
        tf.typeText(smtpServer)
        let nextButton = XCUIApplication().navigationBars.buttons["Next"]
        nextButton.tap()

        XCTAssertTrue(nextButton.exists)
    }

    func testInsertNewWorkingAccount() {
        let account = UITestData.workingAccount

        let tablesQuery = XCUIApplication().tables

        var tf = tablesQuery.cells.textFields["email"]
        tf.typeText(account.email)

        tf = tablesQuery.cells.secureTextFields["password"]
        tf.tap()
        tf.typeText(account.password)

        XCUIApplication().navigationBars.buttons["Next"].tap()

        tf = tablesQuery.textFields["imapServer"]
        tf.typeText(account.imapServerName)
        tf = tablesQuery.textFields["imapPort"]
        tf.tap()
        clearTextField(tf)
        tf.typeText(String(account.imapPort))
        // TODO: Support alert for choosing transport
        XCUIApplication().navigationBars.buttons["Next"].tap()

        tf = tablesQuery.textFields["smtpServer"]
        tf.typeText(account.smtpServerName)
        tf = tablesQuery.textFields["smtpPort"]
        tf.tap()
        clearTextField(tf)
        tf.typeText(String(account.smtpPort))
        // TODO: Support alert for choosing transport
        let nextButton = XCUIApplication().navigationBars.buttons["Next"]
        nextButton.tap()

        waitForever()
    }

    func testInsertNewYahooAccount() {
        let account = UITestData.workingYahooAccount

        let tablesQuery = XCUIApplication().tables

        var tf = tablesQuery.cells.textFields["email"]
        tf.typeText(account.email)

        tf = tablesQuery.cells.secureTextFields["password"]
        tf.tap()
        tf.typeText(account.password)

        XCUIApplication().navigationBars.buttons["Next"].tap()

        tf = tablesQuery.textFields["imapServer"]
        tf.typeText(account.imapServerName)
        tf = tablesQuery.textFields["imapPort"]
        tf.tap()
        clearTextField(tf)
        tf.typeText(String(account.imapPort))
        // TODO: Support alert for choosing transport
        XCUIApplication().navigationBars.buttons["Next"].tap()

        tf = tablesQuery.textFields["smtpServer"]
        tf.typeText(account.smtpServerName)
        tf = tablesQuery.textFields["smtpPort"]
        tf.tap()
        clearTextField(tf)
        tf.typeText(String(account.smtpPort))
        // TODO: Support alert for choosing transport
        let nextButton = XCUIApplication().navigationBars.buttons["Next"]
        nextButton.tap()

        waitForever()
    }
}