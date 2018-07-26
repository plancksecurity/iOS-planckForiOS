//
//  MoveToFolderOperationTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 16.05.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
@testable import pEpForiOS

class MoveToFolderOperationTest: CoreDataDrivenTestBase {
    func testTrashMessage() {
        // Setup 2 accounts
        // the testee
        cdAccount.createRequiredFoldersAndWait()
        Record.saveAndWait()
        // the sender
        let cdAccount2 = SecretTestData().createWorkingCdAccount(number: 1)
        Record.saveAndWait()
        cdAccount2.createRequiredFoldersAndWait()
        Record.saveAndWait()

        // Send (and receive) messages from 2nd account to 1st account
        let receivedMsgs = sendAndReceive(numMails: 1, fromAccount: cdAccount2)

        // User deletes all messages.
        for msg in receivedMsgs {
            msg.imapDelete()
        }

        // Sync
        TestUtil.syncAndWait(numAccountsToSync: 2)

        // Assure deleted messages are in trash
        checkExistance(ofMessages: receivedMsgs, inFolderOfType: .trash, mustExist: true)
    }

    func testMoveInboxToSpam() {
        assureMoveFromInbox(toFolderOfType: .spam)
    }

    func testMoveInboxToTrash() {
        assureMoveFromInbox(toFolderOfType: .trash)
    }

    func testMoveInboxToArchive() {
        assureMoveFromInbox(toFolderOfType: .archive)
    }

    // MARK: - HELPER

    private func assureMoveFromInbox(toFolderOfType targetFolderType: FolderType) {
        // Setup 2 accounts
        // the testee
        cdAccount.createRequiredFoldersAndWait()
        Record.saveAndWait()
        // the sender
        let cdAccount2 = SecretTestData().createWorkingCdAccount(number: 1)
        Record.saveAndWait()
        cdAccount2.createRequiredFoldersAndWait()
        Record.saveAndWait()

        // Send (and receive) messages from 2nd account to 1st account
        let receivedMsgs = sendAndReceive(numMails: 1, fromAccount: cdAccount2)

        // Move messages to target folder
        move(messages: receivedMsgs, toFolerOfType: targetFolderType)

        // Sync
        TestUtil.syncAndWait(numAccountsToSync: 2)

        // Assure messages are in target folder
        checkExistance(ofMessages: receivedMsgs, inFolderOfType: targetFolderType, mustExist: true)
    }

    private func isMandatoryFolderType(type: FolderType) -> Bool {
        return FolderType.requiredTypes.contains(type)
    }

    private func move(messages:[Message], toFolerOfType type: FolderType) {
        for msg in messages {
            guard let targetFolder = msg.parent.account.folder(ofType: type) else {
                // Can't seem to find the target folder. If this is an optional test
                // (working on for certain accounts), ignore it.
                if isMandatoryFolderType(type: type) {
                    XCTFail()
                }
                return
            }
            msg.move(to: targetFolder)
        }
    }

    private func messagesAreEqual(msg1: Message, msg2: Message) -> Bool {
        // For this test we consider messages in a folder as equal if they have the same UUID and none of the
        // comparees has been marked deleted.
        return msg1.uuid == msg2.uuid && msg1.imapFlags?.deleted == msg2.imapFlags?.deleted
    }

    private func messages(msgs: [Message], contain msg: Message) -> Bool {
        if let idx = msgs.index(of: msg) {
            let containedMsg = msgs[idx]
            return messagesAreEqual(msg1: containedMsg, msg2: msg)
        }
        return true
    }
    private func checkExistance(ofMessages msgs: [Message], inFolderOfType type: FolderType,
                                mustExist: Bool) {
        let msgsInFolderToTest = cdAccount.allMessages(inFolderOfType: type).map { $0.message()! }
        for msg in msgs {
            if mustExist {
                XCTAssertTrue(messages(msgs: msgsInFolderToTest, contain: msg))
            } else {
                XCTAssertFalse(messages(msgs: msgsInFolderToTest, contain: msg))
            }
        }
    }

    /// Sends a given number of mails from a given account to `cdAccount`.
    ///
    /// - Parameters:
    ///   - num: number of mails to send
    ///   - sender: account to send mails from
    /// - Returns: the messages received (in inbox) by the recipient
    private func sendAndReceive(numMails num: Int, fromAccount sender: CdAccount) -> [Message] {

        guard let id1 = cdAccount.identity,
            let id2 = sender.identity else {
                XCTFail("We all loose identity ...")
                return []
        }

        // Sync both acocunts and remember what we got before starting the actual test
        TestUtil.syncAndWait(numAccountsToSync: 2)
        let msgsBefore = cdAccount.allMessages(inFolderOfType: .inbox, sendFrom: id2)

        // Create mails from cdAccount2 to cdAccount ...
        let mailsToSend = try! TestUtil.createOutgoingMails(cdAccount: sender,
                                                            numberOfMails: num,
                                                            withAttachments: false,
                                                            encrypt: false)
        XCTAssertEqual(mailsToSend.count, num)

        for mail in mailsToSend {
            guard let currentReceipinets = mail.to?.array as? [CdIdentity] else {
                XCTFail("Should have receipients")
                return []
            }
            mail.from = id2
            mail.removeTos(cdIdentities: currentReceipinets)
            mail.addTo(cdIdentity: id1)
        }
        Record.saveAndWait()    

        // ... and send them.
        TestUtil.syncAndWait(numAccountsToSync: 2)

        // Sync once again to make sure we mirror the servers state (i.e. receive the sent mails)
        TestUtil.syncAndWait(numAccountsToSync: 2)

        // Assure the messages have been received
        let msgsAfter = cdAccount.allMessages(inFolderOfType: .inbox, sendFrom: id2)

        XCTAssertEqual(msgsAfter.count, msgsBefore.count + num)

        let messagesReceived = msgsAfter.filter { !msgsBefore.contains($0) }
        let result = messagesReceived.map { $0.message()! }

        return result
    }
}
