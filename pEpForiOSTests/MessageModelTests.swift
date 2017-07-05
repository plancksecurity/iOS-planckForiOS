//
//  MessageModelTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import pEpForiOS
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
        super.tearDown()
    }

    func testSaveMessageForSending() {
        let testData = TestData()
        let cdAccount = testData.createWorkingCdAccount()
        let account = cdAccount.account()
        account.save()
        let sentFolder = Folder.create(name: "Sent", account: account, folderType: .sent)
        sentFolder.save()
        let msg = sentFolder.createMessage()
        msg.shortMessage = "Some subject"
        msg.from = account.user
        msg.to.append(account.user)
        msg.save()

        guard let cdMsg = CdMessage.first() else {
            XCTFail()
            return
        }
        XCTAssertEqual(msg.uuid, cdMsg.uuid)

        if let (_, _, _) = EncryptAndSendOperation.retrieveNextMessage(
            context: Record.Context.default, cdAccount: cdAccount) {
        } else {
            XCTFail()
        }
    }
}
