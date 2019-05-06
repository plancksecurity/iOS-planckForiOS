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

        dismissInitialSystemAlerts()

        let account = SecretUITestData.workingAccount1
        newAccountSetup(account: account)
        waitForever()
    }

    func testInitialAccountSetup2() {
        app().launch()

        dismissInitialSystemAlerts()

        let account = SecretUITestData.workingAccount2
        newAccountSetup(account: account)
        waitForever()
    }

    func testAdditionalAccount() {
        app().launch()
        addAccount()
        let account = SecretUITestData.workingAccount3
        newAccountSetup(account: account)
        waitForever()
    }

    func testAdditionalManualAccount() {
        app().launch()
        addAdditionalManual(account: SecretUITestData.manualAccount)
    }

    func testAutoAccountPlusManual() {
        app().launch()

        dismissInitialSystemAlerts()

        let account1 = SecretUITestData.workingAccount1
        newAccountSetup(account: account1)

        addAdditionalManual(account: SecretUITestData.manualAccount)
    }

    func testTwoInitialAccounts() {
        app().launch()

        dismissInitialSystemAlerts()

        let account1 = SecretUITestData.workingAccount1
        newAccountSetup(account: account1)

        addAccount()

        let account2 = SecretUITestData.workingAccount2
        newAccountSetup(account: account2)
        waitForever()
    }

    func testNewAccountSetupManual() {
        let theApp = app()

        theApp.launch()

        dismissInitialSystemAlerts()

        var account = SecretUITestData.workingAccount1

        // Wrong password should prevent the automatic login
        let correctPassword = account.password
        account.password += "ShouldNotWork"

        newAccountSetup(account: account)

        switchToManualConfig()

        // Use correct password for the manual setup
        account.password = correctPassword

        manualNewAccountSetup(account)

        waitForever()
    }

    func testNewAccountSetupManualThatFails() {
        let theApp = app()

        theApp.launch()

        dismissInitialSystemAlerts()

        var account = SecretUITestData.workingAccount1

        // Make sure this account will fails, both in auto and manual modes
        account.password += "ShouldNotWork"

        newAccountSetup(account: account)

        switchToManualConfig()

        manualNewAccountSetup(account)

        waitForever()
    }

    func testTriggerGmailOauth2() {
        app().launch()

        dismissInitialSystemAlerts()

        let account = SecretUITestData.gmailOAuth2Account
        newAccountSetup(account: account, enterPassword: false)
        waitForever()
    }

    func testTriggerYahooOauth2() {
        app().launch()

        dismissInitialSystemAlerts()

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

    func typeTextIfEmpty(textField: XCUIElement, text: String) {
        if (textField.value as? String ?? "") == "" {
            textField.typeText(text)
        }
    }

    func manualNewAccountSetup(_ account: UIAccount) {
        let theApp = app()
        let tablesQuery = theApp.tables

        var tf = tablesQuery.cells.textFields["username"]
        typeTextIfEmpty(textField: tf, text: account.nameOfTheUser)

        tf = tablesQuery.cells.textFields["email"]
        tf.tap()
        typeTextIfEmpty(textField: tf, text: account.email)

        tf = tablesQuery.cells.secureTextFields["password"]
        tf.tap()
        tf.typeText(account.password)

        theApp.navigationBars.buttons["Next"].tap()

        tf = tablesQuery.textFields["imapServer"]
        tf.typeText(account.imapServerName)
        tf = tablesQuery.textFields["imapPort"]
        tf.tap()
        tf.clearAndEnter(text: String(account.imapPort))

        tablesQuery.buttons["imapTransportSecurity"].tap()
        let sheet = theApp.sheets["Transport protocol"]
        sheet.buttons[account.imapTransportSecurityString].tap()

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
        signIn(account: account, enterPassword: enterPassword)
    }

    /**
     Dismisses the initial system alerts (access to contacts, allow notifications).
     */
    func dismissInitialSystemAlerts() {
        dismissSystemAlert(buttonTitle: "Allow")
        dismissSystemAlert(buttonTitle: "OK")
    }

    func dismissSystemAlert(buttonTitle: String) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let button = springboard.buttons[buttonTitle]
        if button.exists {
            button.tap()
        } else {
            let exists = NSPredicate(format: "enabled == true")
            expectation(for: exists, evaluatedWith: button, handler: nil)
            waitForExpectations(timeout: 2, handler: nil)
            button.tap()
        }
    }

    func addAdditionalManual(account: UIAccount) {
        addAccount()

        signIn(account: account, enterPassword: true)
        switchToManualConfig()
        manualNewAccountSetup(account)

        waitForever()
    }

    func signIn(account: UIAccount, enterPassword: Bool = true) {
        let theApp = app()
        let textFieldsQuery = theApp.textFields

        var tf = textFieldsQuery["username"]
        tf.tap()
        tf.typeText(account.nameOfTheUser)

        tf = textFieldsQuery["email"]
        tf.tap()
        tf.typeText(account.email)

        if enterPassword {
            tf = theApp.secureTextFields["password"]
            tf.tap()
            tf.typeText(account.password)
        }

        theApp.buttons["Sign In"].tap()
    }

    func switchToManualConfig() {
        let theApp = app()

        let alertOkButton = theApp.buttons["OK"]
        let exists = NSPredicate(format: "enabled == true")
        expectation(for: exists, evaluatedWith: alertOkButton, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)

        alertOkButton.tap()
        theApp.buttons["Manual configuration"].tap()
    }

    func addAccount() {
        let theApp = app()
        theApp.navigationBars["All"].buttons["Folders"].tap()
        theApp.tables.buttons["Add Account"].tap()
    }
}
