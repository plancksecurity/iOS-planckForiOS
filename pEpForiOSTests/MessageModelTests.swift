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
    
    func testAccountSave() {
        CdAccount.sendLayer = DefaultSendLayer()

        // setup AccountDelegate
        let callBack = TestAccountDelegate()
        callBack.expVerifyCalled = expectation(description: "expVerifyCalled")
        MessageModelConfig.accountDelegate = callBack

        let account = TestData.createAccount()
        account.save()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNil(callBack.error)
        })
    }
}
