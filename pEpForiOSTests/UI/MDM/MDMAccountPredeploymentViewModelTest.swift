//
//  MDMAccountPredeploymentViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 04.07.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class MDMAccountPredeploymentViewModelTest: XCTestCase {

    func testSuccess() throws {
        deploy(resultingError: nil)
    }

    func testMalformedAccountData() throws {
        deploy(resultingError: .malformedAccountData)
    }

    func testNetworkError() throws {
        deploy(resultingError: .networkError)
    }
}

// MARK: - Util

extension MDMAccountPredeploymentViewModelTest {
    /// Invokes a VM with the dummy deployer and checks if the result of that
    /// is congruent with the given error,
    /// i.e. that it was successful when there was no error given, and
    /// that it gives an error result otherwise.
    func deploy(resultingError: MDMPredeployedError?) {
        let deployer = DummyDeployer(resultingError: resultingError)
        let vm = MDMAccountPredeploymentViewModel()

        let expDeployed = expectation(description: "expDeployed")

        vm.predeployAccounts(predeployer: deployer) { result in
            switch result {
            case .success(message: _):
                XCTAssertNil(resultingError)
            case .error(message: _):
                XCTAssertNotNil(resultingError)
            }
            expDeployed.fulfill()
        }

        wait(for: [expDeployed], timeout: TestUtil.waitTimeLocal)
    }
}

// MARK: - Util Classes

/// Dummy deployer that synchronously gives the result given in the initializer.
class DummyDeployer: MDMPredeployedProtocol {
    init(resultingError: MDMPredeployedError?) {
        self.resultingError = resultingError
    }

    func accountsToPredeploy() throws -> [(String, String, AccountVerifier.ServerData, AccountVerifier.ServerData)] {
        return []
    }

    func predeployAccounts(callback: @escaping (MDMPredeployedError?) -> ()) {
        callback(resultingError)
    }

    let haveAccountsToPredeploy = true
    let resultingError: MDMPredeployedError?
}
