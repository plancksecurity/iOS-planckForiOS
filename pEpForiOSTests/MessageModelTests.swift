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

class MessageModelTests: CoreDataDrivenTestBase {

    func testSaveMessageForSending() {
        let account = cdAccount.account()
        account.save()
        let outbox = Folder(name: "Sent", parent: nil, account: account, folderType: .outbox)
        outbox.save()
        let msg = outbox.createMessage()
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
            context: Record.Context.main, cdAccount: cdAccount) {
        } else {
            XCTFail()
        }
    }
}
