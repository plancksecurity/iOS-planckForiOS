//
//  NewAccountSetupUITest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

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

    /**
     Clears the given text element.
     */
    func clearTextField(textField: XCUIElement) {
        let string = textField.value as? String
        XCTAssertNotNil(string)

        while (textField.value as? String)?.characters.count > 0 {
            textField.typeText("\u{8}")
        }
    }

    func newAccountSetup(account: Account) {
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

        tablesQuery.buttons["imapTransportSecurity"].tap()
        let sheet = XCUIApplication().sheets["Transport protocol"]
        sheet.collectionViews.buttons[account.imapTransportSecurityString].tap()

        // TODO: Support alert for choosing transport
        XCUIApplication().navigationBars.buttons["Next"].tap()

        tf = tablesQuery.textFields["smtpServer"]
        tf.typeText(account.smtpServerName)
        tf = tablesQuery.textFields["smtpPort"]
        tf.tap()
        clearTextField(tf)
        tf.typeText(String(account.smtpPort))

        tablesQuery.buttons["smtpTransportSecurity"].tap()
        sheet.collectionViews.buttons[account.imapTransportSecurityString].tap()

        let nextButton = XCUIApplication().navigationBars.buttons["Next"]
        nextButton.tap()
    }

    func testNewAccountThatShouldFail() {
        var account = UITestData.workingAccount
        account.password = "CLEArlyWRong"
        newAccountSetup(account)
        // TODO: Verify error message
        waitForever()
    }

    func testInsertNewWorkingAccount() {
        let account = UITestData.workingAccount
        newAccountSetup(account)
        waitForever()
    }

    func testInsertNewYahooAccount() {
        let account = UITestData.workingYahooAccount
        newAccountSetup(account)
        waitForever()
    }
}