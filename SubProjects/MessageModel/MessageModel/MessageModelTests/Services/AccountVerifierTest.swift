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

    func testBasicFail() throws {
        let expVerification = expectation(description: "expVerification")

        let verifier = AccountVerifier()

        guard let imapServer = AccountVerifier.ServerData(loginName: "none",
                                                          hostName: "localhost",
                                                          port: 9999,
                                                          transport: .TLS) else {
            XCTFail()
            return
        }

        guard let smtpServer = AccountVerifier.ServerData(loginName: "none",
                                                          hostName: "localhost",
                                                          port: 9999,
                                                          transport: .TLS) else {
            XCTFail()
            return
        }

        verifier.verify(userName: "none",
                        address: "blagrg@example.com",
                        password: "none",
                        imapServer: imapServer,
                        smtpServer: smtpServer) { maybeError in
            guard let _ = maybeError else {
                XCTFail()
                return
            }
            expVerification.fulfill()
        }

        wait(for: [expVerification], timeout: TestUtil.waitTimeLocal)
    }
}
