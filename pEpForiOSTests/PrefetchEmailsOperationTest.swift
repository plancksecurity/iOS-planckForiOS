//
//  PrefetchEmailsOperationTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 10/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import MessageModel

class PrefetchEmailsOperationTest: XCTestCase {
    var persistentSetup: PersistentSetup!
    let grandOp = GrandOperator()
    
    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()
    }

    override func tearDown() {
        persistentSetup = nil
    }
    
    func testFetchMails() {
        let account = TestData().createWorkingAccount()
        let cdAccount = CdAccount.create(with: account)
        TestUtil.skipValidation()

        guard let connectInfo = (cdAccount.emailConnectInfos.filter {
            $0.key.emailProtocol == .imap }.first?.key) else {
                XCTAssertTrue(false)
                return
        }

        XCTAssertNil(CdMessage.all())

        let exp = expectation(description: "emailFetched")
        let op = PrefetchEmailsOperation(grandOperator: grandOp, connectInfo: connectInfo,
                                         folder: ImapSync.defaultImapInboxName)
        op.completionBlock = {
            exp.fulfill()
        }
        let queue = OperationQueue()
        queue.addOperation(op)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })

        XCTAssertNotNil(CdMessage.all())
        if let msgs = CdMessage.all() {
            XCTAssertGreaterThan(msgs.count, 0)
        }
    }
}
