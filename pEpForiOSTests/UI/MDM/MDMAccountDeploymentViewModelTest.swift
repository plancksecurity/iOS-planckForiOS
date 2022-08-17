//
//  MDMAccountPredeploymentViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 04.07.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

class MDMAccountDeploymentViewModelTest: XCTestCase {

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

extension MDMAccountDeploymentViewModelTest {
    /// Invokes a VM with the dummy deployer and checks if the result of that
    /// is congruent with the given error,
    /// i.e. that it was successful when there was no error given, and
    /// that it gives an error result otherwise.
    func deploy(resultingError: MDMDeploymentError?) {
        let deployer = DummyDeployer(resultingError: resultingError)
        let vm = MDMAccountPredeploymentViewModel()

        let expDeployed = expectation(description: "expDeployed")

        vm.deployAccount(deployer: deployer) { result in
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
class DummyDeployer: MDMDeploymentProtocol {
    init(resultingError: MDMDeploymentError?) {
        self.resultingError = resultingError
    }

    func accountToDeploy() throws -> MDMDeployment.AccountData? {
        return nil
    }

    func deployAccount(password: String, callback: @escaping (MDMDeploymentError?) -> ()) {
        callback(resultingError)
    }

    let haveAccountToDeploy = true
    let resultingError: MDMDeploymentError?
}
