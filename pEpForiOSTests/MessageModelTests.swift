//
//  MessageModelTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

import XCTest

class MessageModelTests: XCTestCase {
    let waitTime = TestUtil.modelSaveWaitTime
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()
    }

    override func tearDown() {
        persistentSetup = nil
    }

    func testAccountSaveAndVerify() {
        let sendLayer = ShortCircuitSendLayer()
        CdAccount.sendLayer = sendLayer

        // setup AccountDelegate
        let accountDelegate = TestUtil.TestAccountDelegate()
        accountDelegate.expVerifyCalled = expectation(description: "expVerifyCalled")
        MessageModelConfig.accountDelegate = accountDelegate

        let account = TestData().createWorkingAccount()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNil(accountDelegate.error)
        })

        guard let ident = Identity.by(address: account.user.address) else {
            XCTFail()
            return
        }
        XCTAssertTrue(ident.isMySelf)
    }
}
