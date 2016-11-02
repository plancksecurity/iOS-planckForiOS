//
//  MessageModelTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel

class MessageModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let _ = PersistentSetup()
    }
    
    func testAccountSave() {
        CdAccount.sendLayer = DefaultSendLayer()

        // setup AccountDelegate
        let accountDelegate = TestUtil.TestAccountDelegate()
        accountDelegate.expVerifyCalled = expectation(description: "expVerifyCalled")
        MessageModelConfig.accountDelegate = accountDelegate

        let account = TestData.createAccount()
        account.save()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNil(accountDelegate.error)
        })
    }
}
