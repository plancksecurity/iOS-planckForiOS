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

    /*
     Use if you want to wait forever. May be useful for debugging.
     */
    func waitForever() {
        let _ = expectation(description: "Never happens")
        waitForExpectations(timeout: 3000, handler: nil)
    }

    /**
     Clears the given text element.
     */
    func clearTextField(_ textField: XCUIElement) {
        let string = textField.value as? String
        XCTAssertNotNil(string)

        while true {
            guard let text = textField.value as? String else {
                break
            }
            if text.characters.count == 0 {
                break
            }
            textField.typeText("\u{8}")
        }
    }

    func typeTextIfEmpty(textField: XCUIElement,  text: String) {
        if (textField.value as? String ?? "") == "" {
            textField.typeText(text)
        }
    }

    func manualNewAccountSetup(_ account: Account) {
        let tablesQuery = XCUIApplication().tables

        var tf = tablesQuery.cells.textFields["nameOfTheUser"]
        typeTextIfEmpty(textField: tf, text: account.nameOfTheUser)

        tf = tablesQuery.cells.textFields["email"]
        tf.tap()
        typeTextIfEmpty(textField: tf, text: account.email)

        tf = tablesQuery.cells.secureTextFields["password"]
        tf.tap()
        typeTextIfEmpty(textField: tf, text: account.password)

        XCUIApplication().navigationBars.buttons["Next"].tap()

        tf = tablesQuery.textFields["imapServer"]
        tf.typeText(account.imapServerName)
        tf = tablesQuery.textFields["imapPort"]
        tf.tap()
        clearTextField(tf)
        tf.typeText(String(account.imapPort))

        tablesQuery.buttons["imapTransportSecurity"].tap()
        let sheet = XCUIApplication().sheets["Transport protocol"]
        sheet.buttons[account.imapTransportSecurityString].tap()

        // TODO: Support alert for choosing transport
        XCUIApplication().navigationBars.buttons["Next"].tap()

        tf = tablesQuery.textFields["smtpServer"]
        tf.typeText(account.smtpServerName)
        tf = tablesQuery.textFields["smtpPort"]
        tf.tap()
        clearTextField(tf)
        tf.typeText(String(account.smtpPort))

        tablesQuery.buttons["smtpTransportSecurity"].tap()
        sheet.buttons[account.smtpTransportSecurityString].tap()

        let nextButton = XCUIApplication().navigationBars.buttons["Next"]
        nextButton.tap()
    }

    func newAccountSetup(account: Account) {
        let tablesQuery = XCUIApplication().tables
        var tfEmail = tablesQuery.cells.textFields["email"]

        tfEmail.tap()
        tfEmail.typeText(account.email)

        tfEmail = tablesQuery.cells.secureTextFields["password"]
        tfEmail.tap()
        tfEmail.typeText(account.password)

        XCUIApplication().tables.cells.buttons["Sign In"].tap()
    }

    func testNewAccountSetup() {
        let account = UITestData.workingAccount1
        newAccountSetup(account: account)
        waitForever()
    }

    func testNewAccountSetupManually() {
        let account = UITestData.manualAccount
        newAccountSetup(account: account)
        XCUIApplication().buttons["Manual configuration"].tap()
        manualNewAccountSetup(account)
        waitForever()
    }

    func testInsertNewWorkingAccount() {
        let account = UITestData.workingAccount1
        manualNewAccountSetup(account)
        waitForever()
    }

    func testNewAccountThatShouldFail() {
        var account = UITestData.workingAccount1
        account.password = "CLEArlyWRong"
        manualNewAccountSetup(account)
        // TODO: Verify error message
        waitForever()
    }

    func testInsertNewYahooAccount() {
        let account = UITestData.workingYahooAccount
        manualNewAccountSetup(account)
        waitForever()
    }

    func testAddSingleWorkingAccounts() {
        let app = XCUIApplication()

        app.navigationBars["Inbox"].buttons["Accounts"].tap()
        app.navigationBars["Accounts"].buttons["Add"].tap()

        let account = UITestData.workingAccount3
        manualNewAccountSetup(account)

        waitForever()
    }

    func testAddTwoWorkingAccounts() {
        let app = XCUIApplication()

        var account = UITestData.workingAccount1
        manualNewAccountSetup(account)

        app.navigationBars["Inbox"].buttons["Accounts"].tap()
        app.navigationBars["Accounts"].buttons["Add"].tap()

        account = UITestData.workingAccount2
        manualNewAccountSetup(account)

        waitForever()
    }
    
    func testAddThreeWorkingAccounts() {
        let app = XCUIApplication()

        var account = UITestData.workingAccount1
        manualNewAccountSetup(account)

        app.navigationBars["Inbox"].buttons["Accounts"].tap()
        app.navigationBars["Accounts"].buttons["Add"].tap()

        account = UITestData.workingAccount2
        manualNewAccountSetup(account)

        app.navigationBars["Inbox"].buttons["Accounts"].tap()
        app.navigationBars["Accounts"].buttons["Add"].tap()

        account = UITestData.workingAccount3
        manualNewAccountSetup(account)
        
        waitForever()
    }
}
