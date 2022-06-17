//
//  AccountVerifierTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 17.06.22.
//  Copyright © 2022 pEp Security S.A. All rights reserved.
//

import XCTest

import MessageModel

class AccountVerifierTest: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testBasicFail() throws {
        let expVerification = expectation(description: "expVerification")

        let verifier = AccountVerifier()
        verifier.verify(address: "blagrg@example.com",
                        userName: "none",
                        password: "none",
                        loginName: "none",
                        serverIMAP: "localhost",
                        portIMAP: 9999,
                        serverSMTP: "localhost",
                        portSMTP: 9999) { maybeError in
            guard let _ = maybeError else {
                XCTFail()
                return
            }
            expVerification.fulfill()
        }

        wait(for: [expVerification], timeout: TestUtil.waitTimeLocal)
    }
}
