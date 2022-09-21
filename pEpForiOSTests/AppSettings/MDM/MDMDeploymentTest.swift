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
            try deployAccount(password: "")
            XCTFail()
        } catch MDMDeploymentError.networkError {
            // expected
        } catch {
            XCTFail()
        }

        let accounts = Account.all()
        XCTAssertEqual(accounts.count, 0)
    }

    func testOk() throws {
        XCTAssertFalse(AppSettings.shared.hasBeenMDMDeployed)
        XCTAssertFalse(MDMDeployment().haveAccountToDeploy)
        setupDeployableAccountData()
        XCTAssertTrue(MDMDeployment().haveAccountToDeploy)

        do {
            try deployAccount(password: "",
                              accountVerifier: TestVerifier(errorToDeliver: nil))
        } catch {
            XCTFail()
        }
    }

    func testWrongPassword() throws {
        XCTAssertFalse(AppSettings.shared.hasBeenMDMDeployed)
        XCTAssertFalse(MDMDeployment().haveAccountToDeploy)
        setupDeployableAccountData()
        XCTAssertTrue(MDMDeployment().haveAccountToDeploy)

        do {
            try deployAccount(password: "surely wrong!",
                              accountVerifier: TestVerifier(errorToDeliver: ImapSyncOperationError.authenticationFailed("", "")))
            XCTFail()
        } catch MDMDeploymentError.authenticationError {
            // expected
        } catch {
            XCTFail()
        }

        let accounts = Account.all()
        XCTAssertEqual(accounts.count, 0)
    }

    // MARK: - Internal Constants

    // MARK: - Util

    /// Resets everything.
    ///
    /// May get called by both setup and tearDown to deal with interruptions during development.
    func reset() {
        AppSettings.shared.hasBeenMDMDeployed = false
        Stack.shared.reset()
        XCTAssertTrue(PEPUtils.pEpClean())
        UserDefaults.standard.set([], forKey: MDMDeployment.keyMDM)
    }

    /// Wrapper around `MDMDeployment.deployAccount` that makes it
    /// a sync method throwing exceptions, easier for tests to use.
    func deployAccount(password: String,
                       accountVerifier: AccountVerifierProtocol = AccountVerifier()) throws {
        var potentialError: Error?

        let expDeployed = expectation(description: "expDeployed")
        MDMDeployment().deployAccount(password: password,
                                      accountVerifier: accountVerifier) { maybeError in
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

    func setupDeployableAccountData() {
        let loginname = "login_name"

        // Note: The use of hard-coded strings as settings keys is intentional.

        let compositionSettingsDict = [AppSettings.keyCompositionSenderName: "sender_name"]

        let imapSettingsDict: SettingsDict = [MDMDeployment.keyIncomingMailSettingsServer: "imap_server",
                                              MDMDeployment.keyIncomingMailSettingsSecurityType: "SSL/TLS",
                                              MDMDeployment.keyIncomingMailSettingsPort: NSNumber(value: 1993),
                                              MDMDeployment.keyIncomingMailSettingsUsername: loginname]

        let smtpSettingsDict: SettingsDict = ["outgoing_mail_settings_server": "smtp_server",
                                              "outgoing_mail_settings_security_type": "STARTTLS",
                                              "outgoing_mail_settings_port": NSNumber(value: 1465),
                                              "outgoing_mail_settings_user_name": loginname]

        let mailSettingsDict: SettingsDict = ["account_email_address": "email@example.com",
                                              "incoming_mail_settings": imapSettingsDict,
                                              "outgoing_mail_settings": smtpSettingsDict]

        let mdmDict = ["composition_settings": compositionSettingsDict,
                       "pep_mail_settings": mailSettingsDict]

        UserDefaults.standard.set(mdmDict, forKey: MDMDeployment.keyMDM)
    }
}

// MARK: - AccountVerifierProtocol

class TestVerifier {
    let errorToDeliver: Error?

    init(errorToDeliver: Error?) {
        self.errorToDeliver = errorToDeliver
    }
}

extension TestVerifier: AccountVerifierProtocol {
    func verify(userName: String,
                address: String,
                password: String,
                imapServer: AccountVerifier.ServerData,
                smtpServer: AccountVerifier.ServerData,
                usePEPFolder: Bool,
                verifiedCallback: @escaping AccountVerifierCallback) {
        DispatchQueue.global().async {
            // Note the strong self in a block.
            // It is assumed that in the tests, the block is _always_ executed
            // and then discarded.
            verifiedCallback(self.errorToDeliver)
        }
    }
}
