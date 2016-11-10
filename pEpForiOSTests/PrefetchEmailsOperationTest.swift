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
    let grandOp = GrandOperator()
    
    override func setUp() {
        super.setUp()
        let _ = PersistentSetup()
    }
    
    func testSimple() {
        let account = TestData().createWorkingAccount()
        account.save()
        TestUtil.skipValidation()

        guard let acc = MessageModel.CdAccount.first() else {
            XCTAssertTrue(false)
            return
        }
        guard let connectInfo = (acc.emailConnectInfos.filter {
            $0.key.emailProtocol == .imap }.first?.key) else {
                XCTAssertTrue(false)
                return
        }

        XCTAssertNil(CdMessage.all())

        let exp = expectation(description: "emailFetched")
        let op = PrefetchEmailsOperation.init(grandOperator: grandOp, connectInfo: connectInfo,
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
    }
}
