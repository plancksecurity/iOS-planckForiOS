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
            if text.count == 0 {
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

    func manualNewAccountSetup(_ account: UIAccount) {
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

    func newAccountSetup(account: UIAccount, enterPassword: Bool = true) {
        let tablesQuery = XCUIApplication().tables

        var tf = tablesQuery.cells.textFields["userName"]
        tf.tap()
        tf.typeText(account.nameOfTheUser)

        tf = tablesQuery.cells.textFields["email"]
        tf.tap()
        tf.typeText(account.email)

        if enterPassword {
            tf = tablesQuery.cells.secureTextFields["password"]
            tf.tap()
            tf.typeText(account.password)
        }

        XCUIApplication().tables.cells.buttons["Sign In"].tap()
    }

    func testInitialAccountSetup() {
        let account = UITestData.workingAccount1
        newAccountSetup(account: account)
        waitForever()
    }

    func testAdditionalAccount() {
        let app = XCUIApplication()
        app.navigationBars["Inbox"].buttons["Folders"].tap()
        app.tables.buttons["add account"].tap()

        let account = UITestData.workingAccount2
        newAccountSetup(account: account)
        waitForever()
    }

    func testTwoInitialAccounts() {
        let account1 = UITestData.workingAccount1
        newAccountSetup(account: account1)

        let app = XCUIApplication()
        app.navigationBars["Inbox"].buttons["Folders"].tap()
        app.tables.buttons["add account"].tap()

        let account2 = UITestData.workingAccount2
        newAccountSetup(account: account2)
        waitForever()
    }

    /// Start app, accept contact permissions manually, start test,
    /// wait for alert and click OK manually
    func testNewAccountSetupManuallyAccountThatDoesNotWorkAutomatically() {
        let account = UITestData.manualAccount
        newAccountSetup(account: account)

        //wait until manual setup button appaers
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(80), execute: {
            XCUIApplication().buttons["Manual configuration"].tap()
            self.manualNewAccountSetup(account)
        })


        waitForever()
    }

    // Adds Yahoo account
    // Note: A working accound must exist already.
    func testAddYahooAccount() {
        openAddAccountManualConfiguration()
        let account = UITestData.workingYahooAccount
        manualNewAccountSetup(account)
        waitForever()
    }

    func testTriggerGmailOauth2() {
        let account = UITestData.gmailOAuth2Account
        newAccountSetup(account: account, enterPassword: false)
        waitForever()
    }

    func testTriggerYahooOauth2() {
        let account = UITestData.yahooOAuth2Account
        newAccountSetup(account: account, enterPassword: false)
        waitForever()
    }

    // Mark: DEBUG ONLY HELPER

    // Opens the "add account" setting in manual configuration mode.
    // Note: A working accound must exist already.
    func openAddAccountManualConfiguration() {
        XCUIDevice.shared.orientation = .faceUp
        XCUIDevice.shared.orientation = .faceUp

        let app = XCUIApplication()
        app.navigationBars["Inbox"].buttons["Folders"].tap()

        let tablesQuery2 = app.tables
        tablesQuery2.buttons["button add"].tap()

        let tablesQuery = tablesQuery2
        tablesQuery.buttons["Sign In"].tap()
        app.alerts["Error"].buttons["Ok"].tap()
        tablesQuery.buttons["Manual configuration"].tap()
    }
}
