//
//  MessageModelTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import MessageModel

class MessageModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        let _ = PersistentSetup.init()
    }
    
    func testAccountSave() {
        // setup AccountDelegate
        class CallBack: AccountDelegate {
            var expVerifyCalled: XCTestExpectation?

            func didVerify(account: Account, error: MessageModelError?) {
                expVerifyCalled?.fulfill()
            }
        }
        let callBack = CallBack()
        callBack.expVerifyCalled = expectation(description: "expVerifyCalled")
        MessageModelConfig.accountDelegate = callBack

        // create account
        let id = Identity.create(address: "user1@example.com", userName: "User 1",
                                 userID: "user1")
        let server = Server.create(serverType: .imap, port: 993, address: "noserverhere",
                                   transport: .tls)
        let cred = ServerCredentials.create(userName: id.userID!, servers: [server])
        let acc = Account.create(identity: id, credentials: [cred])
        acc.save()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }
}
