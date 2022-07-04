//
//  MDMAccountPredeploymentViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 04.07.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

class MDMAccountPredeploymentViewModelTest: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }
}

class DummyDeployer: MDMPredeployedProtocol {
    init(haveAccountsToPredeploy: Bool,
         result: MDMAccountPredeploymentViewModel.Result = .error(message: "blarg")) {
        self.haveAccountsToPredeploy = haveAccountsToPredeploy
        self.result = result
    }

    func predeployAccounts(callback: @escaping (MDMPredeployedError?) -> ()) {
    }

    let haveAccountsToPredeploy: Bool
    let result: MDMAccountPredeploymentViewModel.Result
}
