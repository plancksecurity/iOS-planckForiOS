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
    override func tearDownWithError() throws {
        Stack.shared.reset()
        XCTAssertTrue(PEPUtils.pEpClean())
        try super.tearDownWithError()
    }

    func testNetworkError() throws {
        XCTAssertFalse(AppSettings.shared.hasBeenMDMDeployed)
        XCTAssertFalse(MDMDeployment().haveAccountToDeploy)
        setupDeployableAccountData()
        XCTAssertTrue(MDMDeployment().haveAccountToDeploy)

        do {
            try predeployAccounts()
            XCTFail()
        } catch MDMDeploymentError.networkError {
        } catch {
            XCTFail()
        }

        XCTAssertFalse(AppSettings.shared.hasBeenMDMDeployed)

        let accounts = Account.all()
        XCTAssertEqual(accounts.count, 0)
    }

    // MARK: - Util

    /// Wrapper around `MDMDeployment.deployAccounts` that makes it
    /// a sync method throwing exceptions, easier for tests to use.
    func predeployAccounts() throws {
        var potentialError: Error?

        let expDeployed = expectation(description: "expDeployed")
        MDMDeployment().deployAccounts { maybeError in
            expDeployed.fulfill()
            if let error = maybeError {
                potentialError = error
            } else {
                // After successful deploy, there should not be any accounts to predeploy anymore
                if let mdmDictCheck = UserDefaults.standard.dictionary(forKey: MDMDeployment.keyMDM) {
                    XCTAssertNil(mdmDictCheck[MDMDeployment.keyPredeployedAccounts])
                }
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

        let compositionSettingsDict = ["composition_sender_name": "sender_name"] as SettingsDict

        let imapSettingsDict: [String:Any] = ["incoming_mail_settings_server": "imap_server",
                                              "incoming_mail_settings_security_type": "SSL/TLS",
                                              "incoming_mail_settings_port": NSNumber(value: 1993),
                                              "incoming_mail_settings_user_name": loginname]

        let mailSettingsDict = ["incoming_mail_settings": imapSettingsDict]

        let mdmDict = ["composition_settings": compositionSettingsDict,
                       "pep_mail_settings": mailSettingsDict]

        UserDefaults.standard.set(mdmDict, forKey: "com.apple.configuration.managed")
    }
}
