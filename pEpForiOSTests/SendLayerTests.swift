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
    let grandOp = GrandOperator()
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()
    }

    override func tearDown() {
        persistentSetup = nil
        super.tearDown()
    }

    func testVerifyBad() {
        let accountDelegate = TestUtil.TestAccountDelegate()
        accountDelegate.expVerifyCalled = expectation(description: "expVerifyCalled")
        MessageModelConfig.accountDelegate = accountDelegate

        CdAccount.sendLayer = grandOp
        let account = TestData().createDisfunctionalAccount()
        for cd in account.serverCredentials {
            for s in cd.servers {
                XCTAssertGreaterThan(s.port, 1000)
            }
        }
        XCTAssertNil(CdAccount.all())
        if let accs = CdAccount.all() {
            XCTAssertTrue(accs.isEmpty)
        }

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNotNil(accountDelegate.error)
            XCTAssertTrue(Account.all.isEmpty)
        })
    }

    func testVerifyOk() {
        let accountDelegate = TestUtil.TestAccountDelegate()
        accountDelegate.expVerifyCalled = expectation(description: "expVerifyCalled")
        MessageModelConfig.accountDelegate = accountDelegate

        CdAccount.sendLayer = grandOp
        let _ = TestData().createWorkingAccount()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNil(accountDelegate.error)
            XCTAssertEqual(Account.all.count, 1)
        })
    }
}
