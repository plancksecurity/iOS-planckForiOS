//
//  TrustedServerTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 25.06.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
@testable import pEpForiOS

class TrustedServerTest: CoreDataDrivenTestBase {
    override func setUp() {
        super.setUp()
        Message.swizzleIsTrustedServerToAlwaysTrue()
    }

    override func tearDown() {
        Message.unswizzleIsTrustedServer()
        super.tearDown()
    }
    
    func testMailSend() {
        // Setup 2 accounts
        cdAccount.createRequiredFoldersAndWait(testCase: self)
        Record.saveAndWait()

        let cdAccount2 = SecretTestData().createWorkingCdAccount(number: 1)
        TestUtil.skipValidation()
        Record.saveAndWait()
        cdAccount2.createRequiredFoldersAndWait(testCase: self)
        Record.saveAndWait()

        guard let id1 = cdAccount.identity,
            let id2 = cdAccount2.identity else {
                XCTFail("We all loose identity ...")
                return
        }

        // Sync both acocunts and remember what we got before starting the actual test
        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self, skipValidation: true)
        let msgsInSentAccount1Before = cdAccount.allMessages(inFolderOfType: .sent, sendFrom: id1)
        let msgsInInboxAccount2Before = cdAccount2.allMessages(inFolderOfType: .inbox, sendFrom: id1)

        // Create mail(s) from cdAccount to cdAccount2 ...
        let numMailsToSend = 1
        let mailsToSend = try! TestUtil.createOutgoingMails(cdAccount: cdAccount,
                                                       fromIdentity: cdAccount.identity,
                                                       toIdentity: cdAccount2.identity,
                                                       testCase: self,
                                                       numberOfMails: numMailsToSend,
                                                       withAttachments: false)
        XCTAssertEqual(mailsToSend.count, numMailsToSend)
        Record.saveAndWait()

        // ... and send them.
        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self, skipValidation: true)

        // Now let's see what we got.
        let msgsInSentAccount1After = cdAccount.allMessages(inFolderOfType: .sent, sendFrom: id1)
            .sorted { (msg1: CdMessage, msg2: CdMessage) -> Bool in
                return msg1.sent! < msg2.sent!
            }
            .map { $0.message()! }
        let mailsToSendInSentFolder =
            msgsInSentAccount1After[
                (msgsInSentAccount1After.count - numMailsToSend)...(msgsInSentAccount1After.count - 1)]
//        let msgsInInboxAccount2After = cdAccount2.allMessages(inFolderOfType: .inbox, sendFrom: id1)

        XCTAssertEqual(msgsInSentAccount1After.count,
                       msgsInSentAccount1Before.count + numMailsToSend,
                       "Send mails are in sent folder")

        for msg in mailsToSendInSentFolder {
            let originalRating = msg.getOriginalRatingHeaderRating()
            let rating = msg.pEpRating()
        }
//        XCTAssertEqual(msgsAfter2.count, msgsBefore2.count + numMailsToSend)
    }
}
