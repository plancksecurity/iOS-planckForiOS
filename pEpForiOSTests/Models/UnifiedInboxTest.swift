//
//  UnifiedInboxTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 07.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel

@testable import pEpForiOS

class UnifiedInboxTest: CoreDataDrivenTestBase {

    func testIndexOf() {
        let acc = cdAccount.account()
        acc.save()

        let f1 = Folder(name: "inbox1", parent: nil, account: acc, folderType: .inbox)
        f1.save()

        let f2 = Folder(name: "inbox2", parent: nil, account: acc, folderType: .inbox)
        f2.save()

        let f3 = Folder(name: "inbox3", parent: nil, account: acc, folderType: .inbox)
        f3.save()

        let inboxes = [f1, f2, f3]
        let numMails = 10
        let numMailsTotal = inboxes.count * numMails

        var originalMessages = [Message]()
        var theDate = Date()
        for i in 1...numMails {
            for f in inboxes {
                let message = Message(uuid: "\(i)", parentFolder: f)
                message.longMessage = "long"
                message.shortMessage = "short"
                message.sent = theDate
                message.save()
                theDate = Date(timeInterval: -1, since: theDate)
                originalMessages.append(message)
            }
        }

        for cdM in CdMessage.all() as? [CdMessage] ?? [] {
            cdM.pEpRating = 3
        }
        Record.saveAndWait()

        let uf = UnifiedInbox()
        XCTAssertEqual(uf.messageCount(), numMailsTotal)
        var uid: Int32 = 0

        let cdMessages = uf.allCdMessagesNonThreaded()
        for cdM in cdMessages {
            cdM.uid = uid
            uid += 1
        }
        XCTAssertEqual(uid, Int32(numMailsTotal))
        Record.saveAndWait()

        let allTheCdMessages = uf.allCdMessagesNonThreaded()
        for uidRun in 0..<uid {
            let msg = uf.messageAt(index: Int(uidRun))
            let cdMsg = allTheCdMessages[Int(uidRun)]
            XCTAssertEqual(cdMsg.uid, uidRun)
            XCTAssertEqual(msg?.imapFlags?.uid, uidRun)
        }

        var index = 0
        for msg in originalMessages {
            let i = uf.indexOf(message: msg)
            XCTAssertEqual(i, index)
            index += 1
        }
    }
}
