//
//  SendLayerTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel
import pEpForiOS

class SendLayerTests: XCTestCase {
    let coreDataUtil = CoreDataUtil()
    let connectionManager = ConnectionManager()

    class TestAccountDelegate: AccountDelegate {
        var expVerifyCalled: XCTestExpectation?
        var error: MessageModelError?

        func didVerify(account: Account, error: MessageModelError?) {
            self.error = error
            expVerifyCalled?.fulfill()
        }
    }

    override func setUp() {
        super.setUp()
        let _ = PersistentSetup()
    }

    /**
     For now, make sure you run the following on the command line:
     `python3 -m smtpd -c DebuggingServer -n localhost:4096`
     */
    func testVerifySMTP() {
        let callBack = TestAccountDelegate()
        callBack.expVerifyCalled = expectation(description: "expVerifyCalled")
        MessageModelConfig.accountDelegate = callBack

        let grandOp = GrandOperator(connectionManager: connectionManager,
                                    coreDataUtil: coreDataUtil)
        CdAccount.sendLayer = grandOp
        let account = TestData.createAccount()
        account.save()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNil(callBack.error)
        })
    }
}
