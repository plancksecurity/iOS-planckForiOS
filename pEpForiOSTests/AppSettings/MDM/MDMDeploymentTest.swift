//
//  MDMDeploymentTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel
import pEp4iosIntern

private typealias SettingsDict = [String:Any]

class MDMDeploymentTest: XCTestCase {
    override func setUpWithError() throws {
        reset()
    }

    override func tearDownWithError() throws {
        reset()
    }

    func testNetworkError() throws {
        XCTAssertFalse(AppSettings.shared.hasBeenMDMDeployed)
        XCTAssertFalse(MDMDeployment().haveAccountToDeploy)
        setupDeployableAccountData()
        XCTAssertTrue(MDMDeployment().haveAccountToDeploy)

        do {
            try deployAccount()
            XCTFail()
        } catch MDMDeploymentError.networkError {
        } catch {
            XCTFail()
        }

        let accounts = Account.all()
        XCTAssertEqual(accounts.count, 0)
    }

    // MARK: - Util

    /// Resets everything.
    ///
    /// May get call by both setup and tearDown to deal with interruptions during development.
    func reset() {
        AppSettings.shared.hasBeenMDMDeployed = false
        Stack.shared.reset()
        XCTAssertTrue(PEPUtils.pEpClean())
        UserDefaults.standard.set([], forKey: "com.apple.configuration.managed")
    }

    /// Wrapper around `MDMDeployment.deployAccount` that makes it
    /// a sync method throwing exceptions, easier for tests to use.
    func deployAccount() throws {
        var potentialError: Error?

        let expDeployed = expectation(description: "expDeployed")
        MDMDeployment().deployAccount { maybeError in
            expDeployed.fulfill()
            if let error = maybeError {
                potentialError = error
            } else {
                // A successful deploy should be marked in the settings
                XCTAssertTrue(AppSettings.shared.hasBeenMDMDeployed)
            }
        }
        wait(for: [expDeployed], timeout: TestUtil.waitTime)

        if let error = potentialError {
            throw error
        }
    }

    // MARK: - Setup Util

    /// - Note: The use of hard-coded strings as keys is intentional.
    func setupDeployableAccountData() {
        let loginname = "login_name"

        let compositionSettingsDict = ["composition_sender_name": "sender_name"]

        let imapSettingsDict: SettingsDict = ["incoming_mail_settings_server": "imap_server",
                                              "incoming_mail_settings_security_type": "SSL/TLS",
                                              "incoming_mail_settings_port": NSNumber(value: 1993),
                                              "incoming_mail_settings_user_name": loginname]

        let smtpSettingsDict: SettingsDict = ["outgoing_mail_settings_server": "smtp_server",
                                              "outgoing_mail_settings_security_type": "STARTTLS",
                                              "outgoing_mail_settings_port": NSNumber(value: 1465),
                                              "outgoing_mail_settings_user_name": loginname]

        let mailSettingsDict: SettingsDict = ["account_email_address": "email@example.com",
                                              "incoming_mail_settings": imapSettingsDict,
                                              "outgoing_mail_settings": smtpSettingsDict]

        let mdmDict = ["composition_settings": compositionSettingsDict,
                       "pep_mail_settings": mailSettingsDict]

        UserDefaults.standard.set(mdmDict, forKey: "com.apple.configuration.managed")
    }
}
