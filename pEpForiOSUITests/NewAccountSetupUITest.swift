//
//  NewAccountSetupUITest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 20/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

class NewAccountSetupUITest: XCTestCase {
    // MARK: - Setup

    override func setUp() {
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    // MARK: - Tests

    func testInitialAccountSetup1() {
        app().launch()
        let account = SecretUITestData.workingAccount1
        newAccountSetup(account: account)
        waitForever()
    }

    func testInitialAccountSetup2() {
        app().launch()
        let account = SecretUITestData.workingAccount2
        newAccountSetup(account: account)
        waitForever()
    }

    func testAdditionalAccount() {
        app().launch()
        let theApp = app()
        theApp.navigationBars["Inbox"].buttons["Folders"].tap()
        theApp.tables.buttons["add account"].tap()

        let account = SecretUITestData.workingAccount2
        newAccountSetup(account: account)
        waitForever()
    }

    func testTwoInitialAccounts() {
        app().launch()
        let account1 = SecretUITestData.workingAccount1
        newAccountSetup(account: account1)

        let theApp = app()
        theApp.navigationBars["Inbox"].buttons["Folders"].tap()
        theApp.tables.buttons["add account"].tap()

        let account2 = SecretUITestData.workingAccount2
        newAccountSetup(account: account2)
        waitForever()
    }

    /// Start app, accept contact permissions manually, start test,
    /// wait for alert and click OK manually
    func testNewAccountSetupManual() {
        let theApp = app()

        theApp.launch()

        dismissAlert(app: theApp, buttonTitleToWaitFor: "Allow")
        dismissAlert(app: theApp, buttonTitleToWaitFor: "OK")

        let account = SecretUITestData.manualAccount
        newAccountSetup(account: account)

        let alertOkButton = theApp.buttons["Ok"]
        let exists = NSPredicate(format: "enabled == true")
        expectation(for: exists, evaluatedWith: alertOkButton, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)

        alertOkButton.tap()
        theApp.buttons["Manual configuration"].tap()

        manualNewAccountSetup(account)

        waitForever()
    }

    func dismissAlert(app: XCUIApplication,
                      buttonTitleToWaitFor: String,
                      buttonTitleToPush: String? = nil) {
        let buttonToWaitFor = app.buttons[buttonTitleToWaitFor]

        if !buttonToWaitFor.exists {
            let exists = NSPredicate(format: "enabled == true")
            expectation(for: exists, evaluatedWith: buttonToWaitFor, handler: nil)
            waitForExpectations(timeout: 2, handler: nil)
        }

        let nextTitle = buttonTitleToPush ?? buttonTitleToWaitFor
        let buttonToPush = app.buttons[nextTitle]
        buttonToPush.tap()
    }

    // Adds Yahoo account
    // Note: A working accound must exist already.
    func testAddYahooAccount() {
        app().launch()
        openAddAccountManualConfiguration()
        let account = SecretUITestData.workingYahooAccount
        manualNewAccountSetup(account)
        waitForever()
    }

    func testTriggerGmailOauth2() {
        app().launch()
        let account = SecretUITestData.gmailOAuth2Account
        newAccountSetup(account: account, enterPassword: false)
        waitForever()
    }

    func testTriggerYahooOauth2() {
        app().launch()
        let account = SecretUITestData.yahooOAuth2Account
        newAccountSetup(account: account, enterPassword: false)
        waitForever()
    }

    // MARK: - Helpers

    func app() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["ASAN_OPTIONS": "detect_odr_violation=0"]
        return app
    }

    /*
     Use if you want to wait forever. May be useful for debugging.
     */
    func waitForever() {
        let _ = expectation(description: "Never happens")
        waitForExpectations(timeout: 3000, handler: nil)
    }

    func typeTextIfEmpty(textField: XCUIElement,  text: String) {
        if (textField.value as? String ?? "") == "" {
            textField.typeText(text)
        }
    }

    func manualNewAccountSetup(_ account: UIAccount) {
        let theApp = app()
        let tablesQuery = theApp.tables

        var tf = tablesQuery.cells.textFields["nameOfTheUser"]
        typeTextIfEmpty(textField: tf, text: account.nameOfTheUser)

        tf = tablesQuery.cells.textFields["email"]
        tf.tap()
        typeTextIfEmpty(textField: tf, text: account.email)

        tf = tablesQuery.cells.secureTextFields["password"]
        tf.tap()
        typeTextIfEmpty(textField: tf, text: account.password)

        theApp.navigationBars.buttons["Next"].tap()

        tf = tablesQuery.textFields["imapServer"]
        tf.typeText(account.imapServerName)
        tf = tablesQuery.textFields["imapPort"]
        tf.tap()
        tf.clearAndEnter(text: String(account.imapPort))

        tablesQuery.buttons["imapTransportSecurity"].tap()
        let sheet = theApp.sheets["Transport protocol"]
        sheet.buttons[account.imapTransportSecurityString].tap()

        // TODO: Support alert for choosing transport
        theApp.navigationBars.buttons["Next"].tap()

        tf = tablesQuery.textFields["smtpServer"]
        tf.typeText(account.smtpServerName)
        tf = tablesQuery.textFields["smtpPort"]
        tf.tap()
        tf.clearAndEnter(text: String(account.smtpPort))

        tablesQuery.buttons["smtpTransportSecurity"].tap()
        sheet.buttons[account.smtpTransportSecurityString].tap()

        let nextButton = theApp.navigationBars.buttons["Next"]
        nextButton.tap()
    }

    func newAccountSetup(account: UIAccount, enterPassword: Bool = true) {
        let theApp = app()
        let tablesQuery = theApp.tables

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

        theApp.tables.cells.buttons["Sign In"].tap()
    }

    // Opens the "add account" setting in manual configuration mode.
    // Note: A working accound must exist already.
    func openAddAccountManualConfiguration() {
        XCUIDevice.shared.orientation = .faceUp
        XCUIDevice.shared.orientation = .faceUp

        let theApp = app()
        theApp.navigationBars["Inbox"].buttons["Folders"].tap()

        let tablesQuery2 = theApp.tables
        tablesQuery2.buttons["button add"].tap()

        let tablesQuery = tablesQuery2
        tablesQuery.buttons["Sign In"].tap()
        theApp.alerts["Error"].buttons["Ok"].tap()
        tablesQuery.buttons["Manual configuration"].tap()
    }
}
