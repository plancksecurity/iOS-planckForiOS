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

    override func setUp() {
        super.setUp()
        let _ = PersistentSetup()
    }

    func testVerifyNotWorking() {
        let accountDelegate = TestUtil.TestAccountDelegate()
        accountDelegate.expVerifyCalled = expectation(description: "expVerifyCalled")
        MessageModelConfig.accountDelegate = accountDelegate

        let grandOp = GrandOperator(connectionManager: connectionManager,
                                    coreDataUtil: coreDataUtil)
        CdAccount.sendLayer = grandOp
        let account = TestData().createDisfunctionalAccount()
        account.save()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNotNil(accountDelegate.error)
        })
    }

    func testVerify() {
        let accountDelegate = TestUtil.TestAccountDelegate()
        accountDelegate.expVerifyCalled = expectation(description: "expVerifyCalled")
        MessageModelConfig.accountDelegate = accountDelegate

        let grandOp = GrandOperator(connectionManager: connectionManager,
                                    coreDataUtil: coreDataUtil)
        CdAccount.sendLayer = grandOp
        let account = TestData().createWorkingAccount()
        account.save()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNil(accountDelegate.error)
        })
    }
}
