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

        let account = secretTestData().workingAccount1
        newAccountSetup(account: account)
        waitForever()
    }

    func testInitialAccountSetup2() {
        app().launch()

        dismissInitialSystemAlerts()

        let account = secretTestData().workingAccount2
        newAccountSetup(account: account)
        waitForever()
    }

    func testAdditionalAccount() {
        app().launch()
        addAccount()
        let account = secretTestData().workingAccount3
        newAccountSetup(account: account)
        waitForever()
    }

    func testAdditionalManualAccount() {
        app().launch()
        let account = secretTestData().workingAccount1
        let (manualAccount, correctPassword) = accountToManual(account: account)
        addAdditionalManual(account: manualAccount, correctPassword: correctPassword)
    }

    func testAutoAccountPlusManual() {
        app().launch()

        dismissInitialSystemAlerts()

        let account1 = secretTestData().workingAccount1
        newAccountSetup(account: account1)

        let account2 = secretTestData().workingAccount2
        let (manualAccount, correctPassword) = accountToManual(account: account2)
        addAdditionalManual(account: manualAccount, correctPassword: correctPassword)
    }

    func testTwoInitialAccounts() {
        app().launch()

        dismissInitialSystemAlerts()

        let account1 = secretTestData().workingAccount1
        newAccountSetup(account: account1)

        addAccount()

        let account2 = secretTestData().workingAccount2
        newAccountSetup(account: account2)
        waitForever()
    }

    func testNewAccountSetupManual() {
        let theApp = app()

        theApp.launch()

        dismissInitialSystemAlerts()

        let account = secretTestData().workingAccount1

        var (manualAccount, correctPassword) = accountToManual(account: account)

        newAccountSetup(account: manualAccount)

        switchToManualConfig()

        // Use correct password for the manual setup
        manualAccount.password = correctPassword

        manualNewAccountSetup(manualAccount, expectServerDetailsToBeAlreadyFilledIn: true)

        waitForever()
    }

    func testNewAccountSetupManualThatFails() {
        let theApp = app()

        theApp.launch()

        dismissInitialSystemAlerts()

        var account = secretTestData().workingAccount1

        // Make sure this account will fails, both in auto and manual modes
        account.password += "ShouldNotWork"

        newAccountSetup(account: account)

        switchToManualConfig()

        manualNewAccountSetup(account, expectServerDetailsToBeAlreadyFilledIn: true)

        waitForever()
    }

    func testTriggerGmailOauth2() {
        app().launch()

        dismissInitialSystemAlerts()

        let account = secretTestData().gmailOAuth2Account
        newAccountSetup(account: account, enterPassword: false)
        waitForever()
    }

    func testTriggerYahooOauth2() {
        app().launch()

        dismissInitialSystemAlerts()

        let account = secretTestData().yahooOAuth2Account
        newAccountSetup(account: account, enterPassword: false)
        waitForever()
    }

    // MARK: - Helpers

    func app() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["ASAN_OPTIONS": "detect_odr_violation=0"]
        return app
    }

    func secretTestData() -> UITestDataProtocol {
        return SecretUITestData()
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

    /// - Parameters:
    ///     - account: The account info from which to get the data to fill in.
    ///     - expectServerDetailsToBeAlreadyFilledIn:
    ///       If this is set to true, then the expectation is that
    ///       server details are already filled in.
    ///       The use case is a successful lookup of account details,
    ///       with the wrong password, to force the manual setup.
    func manualNewAccountSetup(_ account: UIAccount,
                               expectServerDetailsToBeAlreadyFilledIn: Bool) {
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

        let sheet = theApp.sheets["Transport protocol"]

        if !expectServerDetailsToBeAlreadyFilledIn {
            tf = tablesQuery.textFields["imapServer"]
            tf.typeText(account.imapServerName)
            tf = tablesQuery.textFields["imapPort"]
            tf.tap()
            tf.clearAndEnter(text: String(account.imapPort))

            tablesQuery.buttons["imapTransportSecurity"].tap()
            sheet.buttons[account.imapTransportSecurityString].tap()
        }

        theApp.navigationBars.buttons["Next"].tap()

        if !expectServerDetailsToBeAlreadyFilledIn {
            tf = tablesQuery.textFields["smtpServer"]
            tf.typeText(account.smtpServerName)
            tf = tablesQuery.textFields["smtpPort"]
            tf.tap()
            tf.clearAndEnter(text: String(account.smtpPort))

            tablesQuery.buttons["smtpTransportSecurity"].tap()
            sheet.buttons[account.smtpTransportSecurityString].tap()
        }

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

    func addAdditionalManual(account: UIAccount, correctPassword: String) {
        addAccount()

        signIn(account: account, enterPassword: true)
        switchToManualConfig()
        manualNewAccountSetup(account, expectServerDetailsToBeAlreadyFilledIn: true)

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

    /// For the given account, sets the password to something that should not work,
    /// transforming it into an account that requires manual setup.
    /// - Returns: The account (that will require manual setup) plus the original password
    ///            as a tuple.
    func accountToManual(account: UIAccount) -> (UIAccount, String) {
        var theAccount = account
        // Wrong password should prevent the automatic login
        let correctPassword = account.password
        theAccount.password += "ShouldNotWork"
        return (theAccount, correctPassword)
    }
}
