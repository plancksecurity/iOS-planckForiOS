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
        setupAccountData = nil
    }

    override func tearDownWithError() throws {
        Stack.shared.reset()
        XCTAssertTrue(PEPUtils.pEpClean())
        try super.tearDownWithError()
    }

    func testNetworkError() throws {
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

    /// The MDM account data that is expected to be deployed.
    var setupAccountData: MDMDeployment.AccountData? = nil

    func setupDeployableAccountData() {
    }
}
