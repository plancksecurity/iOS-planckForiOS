//
//  ContentDispositionTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 18.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
@testable import pEpForiOS

class ContentDispositionTest: CoreDataDrivenTestBase {
    // Commented as randomly failing and crashing. See IOS-1465. //!!!:
//    func testInlinedAttachmentRoundTrip() {
//        attchmentRoundTrip(attachmentsInlined: true)
//    }

    // Commented as randomly failing. See IOS-1382.
//    func testNonInlinedAttachmentRoundTrip() {
//        attchmentRoundTrip(attachmentsInlined: false)
//    }

    // MARK: - HELPER

    /// Tests if sent attachments are received with correct content disposition
    func attchmentRoundTrip(attachmentsInlined: Bool) {
        // Setup 2 accounts
        cdAccount.createRequiredFoldersAndWait(testCase: self)
        moc.saveAndLogErrors()

        let cdAccount2 = SecretTestData().createWorkingCdAccount(number: 1, context: moc)
        moc.saveAndLogErrors()
        cdAccount2.createRequiredFoldersAndWait(testCase: self)
        moc.saveAndLogErrors()

        guard let id1 = cdAccount.identity,
            let id2 = cdAccount2.identity else {
                XCTFail("We all loose identity ...")
                return
        }

        // Sync both acocunts and remember what we got before starting the actual test
        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self)
        let msgsBeforeId2 = cdAccount2.allMessages(inFolderOfType: .inbox, sendFrom: id1, in: moc)

        // Create mails from ID1 to ID2 with attachments (inlined or not)
        let dateBeforeSend = Date().addingTimeInterval(-1.0)
        let numMailsToSend = 1
        let mailsToSend = try!
            TestUtil.createOutgoingMails(cdAccount: cdAccount,
                                         fromIdentity: id1,
                                         toIdentity: id2,
                                         setSentTimeOffsetForManualOrdering: false,
                                         testCase: self,
                                         numberOfMails: numMailsToSend,
                                         withAttachments: true,
                                         attachmentsInlined: attachmentsInlined,
                                         encrypt: false,
                                         forceUnencrypted: true,
                                         context: moc)
        XCTAssertEqual(mailsToSend.count, numMailsToSend)

        // ... and send them.
        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self)

        // Sync once again. Just to make sure we mirror the servers state (i.e. receive the
        // sent mails)
        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self)

        // Now let's see what we got.
        let msgsAfterId2 = cdAccount2.allMessages(inFolderOfType: .inbox, sendFrom: id1, in: moc)
        XCTAssertEqual(msgsAfterId2.count, msgsBeforeId2.count + numMailsToSend)

        // Ignore messages that have not been created by this test
        let testees = msgsAfterId2.filter {
            guard let sent = $0.sent else {
                XCTFail("No sent")
                return false
            }
            return sent > dateBeforeSend
        }
        XCTAssertEqual(testees.count, numMailsToSend)

        // Assure the contentDisposition is correct (as sent)
        for cdMessage in testees {
            guard let cdAttachments = cdMessage.attachments?.array as? [CdAttachment] else {
                XCTFail("No attachments")
                continue
            }
            XCTAssertGreaterThan(cdAttachments.count, 0)
            for cdAttachment in cdAttachments {
                guard let contentDisposition = Attachment.ContentDispositionType(rawValue:
                        cdAttachment.contentDispositionTypeRawValue)
                    else {
                        XCTFail("Missing data")
                        continue
                }
                if attachmentsInlined {
                    XCTAssertTrue(contentDisposition == .inline)
                } else {
                    XCTAssertTrue(contentDisposition == .attachment)
                }
            }
        }
    }
}
