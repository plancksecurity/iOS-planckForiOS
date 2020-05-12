//IOS-2241 CRASHES
////
////  MoveToFolderOperationTest.swift
////  pEpForiOSTests
////
////  Created by Andreas Buff on 16.05.18.
////  Copyright © 2018 p≡p Security S.A. All rights reserved.
////
//
//import XCTest
//import CoreData
//
//@testable import MessageModel
//
//    // Commented as randomly failing. See IOS-1382.
//class MoveToFolderOperationTest: PersistentStoreDrivenTestBase {
//
//    // MARK: - Trash message
//
//    func testTrashMessage() {
//        // Setup 2 accounts
//        // the testee
//        cdAccount.createRequiredFoldersAndWait(testCase: self)
//        moc.saveAndLogErrors()
//        // the sender
//        let cdAccount2 = SecretTestData().createWorkingCdAccount(context: moc, number: 1)
//        moc.saveAndLogErrors()
//        cdAccount2.createRequiredFoldersAndWait(testCase: self)
//        moc.saveAndLogErrors()
//
//        // Send (and receive) messages from 2nd account to 1st account
//        let receivedMsgs = sendAndReceive(numMails: 1, fromAccount: cdAccount2)
//
//        // User deletes all messages.
//        for msg in receivedMsgs {
//            Message.imapDelete(messages: [msg])
//        }
//
//        // Sync
//        TestUtil.makeFolderInteresting(folderType: .trash, cdAccount: cdAccount)
//        TestUtil.syncAndWait(testCase: self)
//
//        // Assure deleted messages are in trash
//        checkExistance(ofMessages: receivedMsgs, inFolderOfType: .trash, in: cdAccount, mustExist: true)
//    }
//
//    // MARK: - Move from inbox to different folder
//
//    func testMoveInboxToSent() {
//        assureMoveFromInbox(toFolderOfType: .sent)
//    }
//
//    func testMoveInboxToTrash() {
//        assureMoveFromInbox(toFolderOfType: .trash)
//    }
//
//    func testMoveInboxToInbox() {
//        assureMoveFromInbox(toFolderOfType: .inbox)
//    }
//
//    // MARK: - Move from inbox to different account (IOS-1360)
//
//    func testMoveToOtherAccount_inbox() {
//        assureMoveFromInbox(toFolderOfType: .inbox, inDifferentAccount: true)
//    }
//
//    func testMoveToOtherAccount_sent() {
//        assureMoveFromInbox(toFolderOfType: .sent, inDifferentAccount: true)
//    }
//
//    func testMoveToOtherAccount_trash() {
//        assureMoveFromInbox(toFolderOfType: .trash, inDifferentAccount: true)
//    }
//
//    // MARK: - HELPER
//
//    private func assureMoveFromInbox(toFolderOfType targetFolderType: FolderType,
//                                     inDifferentAccount: Bool = false) {
//        // Setup 2 accounts
//        // the testee
//        cdAccount.createRequiredFoldersAndWait(testCase: self)
//        moc.saveAndLogErrors()
//        // the sender
//        let cdAccount2 = SecretTestData().createWorkingCdAccount(context: moc, number: 1)
//        moc.saveAndLogErrors()
//        cdAccount2.createRequiredFoldersAndWait(testCase: self)
//        moc.saveAndLogErrors()
//
//        // Send (and receive) messages from 2nd account to 1st account
//        let receivedMsgs = sendAndReceive(numMails: 1, fromAccount: cdAccount2)
//
//        let targetCdAccount: CdAccount = inDifferentAccount ? cdAccount2 : cdAccount
//        // Move messages to target folder
//        move(messages: receivedMsgs,
//             toFolderOfType: targetFolderType,
//             in: targetCdAccount.account())
//
//        TestUtil.makeFolderInteresting(folderType: targetFolderType, cdAccount: targetCdAccount)
//        // Sync
//        TestUtil.syncAndWait(testCase: self)
//
//        // Assure messages are in target folder
//        checkExistance(ofMessages: receivedMsgs,
//                       inFolderOfType: targetFolderType,
//                       in: targetCdAccount,
//                       mustExist: true)
//    }
//
//    private func isMandatoryFolderType(type: FolderType) -> Bool {
//        return FolderType.requiredTypes.contains(type)
//    }
//
//    private func move(messages:[Message], toFolderOfType type: FolderType, in account: Account) {
//        for msg in messages {
//            guard let targetFolder = account.firstFolder(ofType: type) else {
//                // Can't seem to find the target folder. If this is an optional test
//                // (working on for certain accounts), ignore it.
//                if isMandatoryFolderType(type: type) {
//                    XCTFail()
//                }
//                return
//            }
//            Message.move(messages: [msg], to: targetFolder)
//        }
//    }
//
//    private func messagesAreEqual(msg1: Message, msg2: Message) -> Bool {
//        // For this test we consider messages in a folder as equal if they have the same UUID.
//        return msg1.uuid == msg2.uuid
//    }
//
//    private func messages(msgs: [Message], contain msg: Message) -> Bool {
//        for testee in msgs {
//            if messagesAreEqual(msg1: testee, msg2: msg) {
//                return true
//            }
//        }
//        return false
//    }
//
//    private func checkExistance(ofMessages msgs: [Message],
//                                inFolderOfType type: FolderType,
//                                in cdAccountToCheck: CdAccount,
//                                mustExist: Bool) {
//        let msgsInFolderToTest = cdAccountToCheck.allMessages(inFolderOfType: type)
//            .map { MessageModelObjectUtils.getMessage(fromCdMessage: $0) }
//        for msg in msgs {
//            if mustExist {
//                XCTAssertTrue(messages(msgs: msgsInFolderToTest, contain: msg))
//            } else {
//                XCTAssertFalse(messages(msgs: msgsInFolderToTest, contain: msg))
//            }
//        }
//    }
//
//    /// Sends a given number of mails from a given account to `cdAccount`.
//    ///
//    /// - Parameters:
//    ///   - num: number of mails to send
//    ///   - sender: account to send mails from
//    /// - Returns: the messages received (in inbox) by the recipient
//    private func sendAndReceive(numMails num: Int, fromAccount sender: CdAccount) -> [Message] {
//
//        guard let id1 = cdAccount.identity,
//            let id2 = sender.identity else {
//                XCTFail("We all loose identity ...")
//                return []
//        }
//
//        // Sync both acocunts and remember what we got before starting the actual test
//        TestUtil.syncAndWait(testCase: self)
//        let msgsBefore = cdAccount.allMessages(inFolderOfType: .inbox, sendFrom: id2)
//
//        // Create mails from cdAccount2 to cdAccount ...
//        let mailsToSend = try! TestUtil.createOutgoingMails(cdAccount: sender,
//                                                            testCase: self,
//                                                            numberOfMails: num,
//                                                            withAttachments: false,
//                                                            encrypt: false,
//                                                            context: moc)
//        XCTAssertEqual(mailsToSend.count, num)
//
//        for mail in mailsToSend {
//            guard let currentReceipinets = mail.to?.array as? [CdIdentity] else {
//                XCTFail("Should have receipients")
//                return []
//            }
//            mail.from = id2
//            mail.removeFromTo(NSOrderedSet(array: currentReceipinets))
//            mail.addToTo(id1)
//        }
//        moc.saveAndLogErrors()
//
//        // ... and send them.
//        TestUtil.syncAndWait(testCase: self)
//
//        // Sync once again to make sure we mirror the servers state (i.e. receive the sent mails)
//        TestUtil.syncAndWait(testCase: self)
//
//        // Assure the messages have been received
//        let msgsAfter = cdAccount.allMessages(inFolderOfType: .inbox, sendFrom: id2)
//
//        XCTAssertEqual(msgsAfter.count, msgsBefore.count + num)
//
//        let messagesReceived = msgsAfter.filter { !msgsBefore.contains($0) }
//        let result = messagesReceived.map { MessageModelObjectUtils.getMessage(fromCdMessage: $0) }
//
//        return result
//    }
//}
