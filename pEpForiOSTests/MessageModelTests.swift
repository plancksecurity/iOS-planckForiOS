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
        let outbox = Folder(name: "Outbox", parent: nil, account: account, folderType: .outbox)
        outbox.save()

        let msg = Message(uuid: MessageID.generate(), parentFolder: outbox)
        msg.shortMessage = "Some subject"
        msg.from = account.user
        msg.appendToTo(account.user)
        msg.save()

        guard let cdMsg = CdMessage.first() else {
            XCTFail()
            return
        }
        XCTAssertEqual(msg.uuid, cdMsg.uuid)

        if let _ = EncryptAndSendOperation.retrieveNextMessage(context: Record.Context.main,
                                                               cdAccount: cdAccount) {
        } else {
            XCTFail()
        }
    }
}
