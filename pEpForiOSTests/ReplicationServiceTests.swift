//
//  ReplicationServiceTests.swift
//  pEpForiOS
//
//  Created by hernani on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
@testable import pEpForiOS

class ReplicationServiceTests: XCTestCase {
    //!!!:  needs complete rewrite.
    // Has randomly failing tests
    // Depends on MessageModelConfig.messageFolderDelegate, which is gone for good


//    var persistenceSetup: PersistentSetup!
//    var moc: NSManagedObjectContext!
//
//    override func setUp() {
//        super.setUp()
//        persistenceSetup = PersistentSetup()
//        moc = Stack.shared.mainContext
//    }
//
//    override func tearDown() {
//        persistenceSetup = nil
//        super.tearDown()
//    }
//
//    func testSyncOutgoing() {
////        testSyncOutgoing(useCorrectSmtpAccount: true)
//    }
//
//    func testSyncOutgoingWithWrongAccount() {
////        testSyncOutgoing(useCorrectSmtpAccount: false)
//    }
//
//    //!!!: random fail
////    func testSyncOneTime() {
////        XCTAssertNil(CdAccount.all())
////        XCTAssertNil(CdFolder.all())
////        XCTAssertNil(CdMessage.all())
////
////        let modelDelegate = MessageModelObserver()
//////        MessageModelConfig.messageFolderDelegate = modelDelegate // gone for good
////
////        let replicationService = ReplicationService(parentName: #function)
////
////        let del = ReplicationServiceObserver(
////            expAccountsSynced: expectation(description: "expSingleAccountSynced"))
////        replicationService.unitTestDelegate = del
////        replicationService.delegate = del
////
////        _ = SecretTestData().createWorkingCdAccount()
////        Record.saveAndWait()
////
////        replicationService.start()
////
////        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
////            XCTAssertNil(error)
////        })
////
////        XCTAssertNotNil(del.accountInfo)
////        XCTAssertNotNil(CdFolder.all())
////
////        guard let cdFolder = CdFolder.first(
////            attributes: ["folderTypeRawValue": FolderType.inbox.rawValue]) else {
////                XCTFail()
////                return
////        }
////        XCTAssertGreaterThanOrEqual(cdFolder.messages?.count ?? 0, 0)
////        let allCdMessages = cdFolder.messages?.sortedArray(
////            using: [NSSortDescriptor(key: "uid", ascending: true)]) as? [CdMessage] ?? []
////        XCTAssertGreaterThanOrEqual(allCdMessages.count, 0)
////
////        for cdMsg in allCdMessages {
////            guard let parentF = cdMsg.parent else {
////                XCTFail()
////                continue
////            }
////            XCTAssertEqual(parentF.folderType, FolderType.inbox)
////        }
////
////        let unifiedInbox = UnifiedInbox()
////
////        let unifiedMessageCount = unifiedInbox.messageCount()
////        XCTAssertGreaterThanOrEqual(unifiedMessageCount, 0)
////        for i in 0..<unifiedMessageCount {
////            guard let msg = unifiedInbox.messageAt(index: i) else {
////                XCTFail()
////                continue
////            }
////
////            XCTAssertTrue(msg.isValidMessage())
////
////            let pEpRating = Int16(msg.pEpRatingInt ?? -1)
////            XCTAssertNotEqual(pEpRating, PEPUtil.pEpRatingNone)
////            if !modelDelegate.contains(messageID: msg.messageID) {
////                XCTFail()
////            }
////        }
////
////        let inbox = Folder.from(cdFolder: cdFolder)
////        XCTAssertEqual(modelDelegate.messages.count, unifiedMessageCount)
////
////        for msg in modelDelegate.messages {
////            let msgIsFlaggedDeleted = msg.imapFlags?.deleted ?? false
////            XCTAssertTrue(!msgIsFlaggedDeleted)
////            XCTAssertTrue(inbox.contains(message: msg))
////            if !unifiedInbox.contains(message: msg) {
////                XCTFail()
////            }
////        }
////        XCTAssertFalse(modelDelegate.hasChangedMessages)
////
////        TestUtil.cancelReplicationServiceAndWait(replicationService: replicationService, testCase: self)
////    }
//
//    func testCancelSyncImmediately() {
//        XCTAssertNil(CdAccount.all())
//        XCTAssertNil(CdFolder.all())
//        XCTAssertNil(CdMessage.all())
//
//        let replicationService = ReplicationService(parentName: #function)
//
//        _ = SecretTestData().createWorkingCdAccount(context: moc)
//        Record.saveAndWait()
//
//        for _ in 0...10 {
//            replicationService.start()
//            TestUtil.cancelReplicationServiceAndWait(replicationService: replicationService, testCase: self)
//        }
//
//        XCTAssertNil(CdFolder.all())
//        XCTAssertNil(CdMessage.all())
//    }
//
//    class MySelfObserver: KickOffMySelfProtocol {
//        let expMySelfed: XCTestExpectation?
//        let queue = LimitedOperationQueue()
//        let backgrounder: MockBackgrounder
//
//        init(expMySelfed: XCTestExpectation?,
//             expBackgroundTaskFinishedAtLeastOnce: XCTestExpectation?) {
//            self.expMySelfed = expMySelfed
//            backgrounder = MockBackgrounder(
//                expBackgroundTaskFinishedAtLeastOnce: expBackgroundTaskFinishedAtLeastOnce)
//        }
//
//        func startMySelf() {
//            let op = MySelfOperation(parentName: #function, backgrounder: backgrounder)
//            op.completionBlock = {
//                op.completionBlock = nil
//                self.expMySelfed?.fulfill()
//            }
//            queue.addOperation(op)
//        }
//    }
//
//    //MARK: HELPER
//
//    func testSyncOutgoing(useCorrectSmtpAccount: Bool) {
//        XCTAssertNil(CdAccount.all())
//        XCTAssertNil(CdFolder.all())
//        XCTAssertNil(CdMessage.all())
//
//        let modelDelegate = MessageModelObserver()
//        MessageModelConfig.messageFolderDelegate = modelDelegate
//
//        let cdAccount =
//            useCorrectSmtpAccount ?
//            SecretTestData().createWorkingCdAccount(context: moc) :
//            SecretTestData().createSmtpTimeOutCdAccount(context: moc)
//        Record.saveAndWait()
//
//        TestUtil.syncAndWait(testCase: self)
//
//        let from = CdIdentity(context: moc)
//        from.userName = cdAccount.identity?.userName ?? "Unit 004"
//        from.address = cdAccount.identity?.address ?? "unittest.ios.4@peptest.ch"
//
//        let to = CdIdentity(context: moc)
//        to.userName = "Unit 001"
//        to.address = "unittest.ios.1@peptest.ch"
//
//        guard let sentFolder = CdFolder.by(folderType: .sent, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//        XCTAssertEqual((sentFolder.messages ?? NSSet()).count, 0)
//
//        let numMails = 1
//        let outgoingMails = try! TestUtil.createOutgoingMails(cdAccount: cdAccount,
//                                                              testCase: self,
//                                                              numberOfMails: numMails,
//                                                              context: moc)
//        let outgoingMessageIDs: [String] = outgoingMails
//            .map() { $0.messageID ?? "" }
//            .filter() { $0 != "" }
//
//        // Verify outgoing mails
//        for m in outgoingMails {
//            XCTAssertEqual(m.parent?.folderType, FolderType.outbox)
//            XCTAssertEqual(m.uid, Int32(0))
//        }
//
//        TestUtil.syncAndWait(testCase: self)
//
//        // Check that the sent mails have been deleted
//        Stack.refreshRegisteredObjects(mergeChanges: true, in: moc)
//        if useCorrectSmtpAccount {
//            for m in outgoingMails {
//                XCTAssertTrue(m.isDeleted)
//            }
//        }
//
//        // sync
//        TestUtil.syncAndWait(testCase: self)
//
//        if useCorrectSmtpAccount {
//            // those messages do not exist if we are using an incorrect account
//            TestUtil.checkForExistanceAndUniqueness(uuids: outgoingMessageIDs)
//        }
//    }
//
//    class MessageModelObserver: MessageFolderDelegate {
//        var messages: [Message] {
//            var messages = [Message]()
//            for ms in messagesByID.values {
//                for m in ms {
//                    messages.append(m)
//                }
//            }
//            return messages.sorted { m1, m2 in
//                if let d1 = m1.sent, let d2 = m2.sent {
//                    return areInIncreasingOrder(d1: d1, d2: d2)
//                }
//                return false
//            }
//        }
//        var messagesByID = [MessageID: [Message]]()
//        var changedMessagesByID = [MessageID: Message]()
//
//        var hasChangedMessages: Bool {
//            return !changedMessagesByID.isEmpty
//        }
//
//        func contains(messageID: MessageID) -> Bool {
//            return messagesByID[messageID] != nil
//        }
//
//        func areInIncreasingOrder(d1: Date, d2: Date) -> Bool {
//            switch d1.compare(d2 as Date) {
//            case .orderedAscending: return true
//            default: return false
//            }
//        }
//
//        func add(message: Message) {
//            if let existing = messagesByID[message.uuid] {
//                var news = existing
//                news.append(message)
//                messagesByID[message.uuid] = news
//            } else {
//                messagesByID[message.uuid] = [message]
//            }
//        }
//
//        func didUpdate(message: Message) {
//            // messages has been changed during the test
//            XCTAssertNotNil(messagesByID[message.messageID])
//            add(message: message)
//            changedMessagesByID[message.messageID] = message
//        }
//
//        func didDelete(message: Message) {
//            // this message has been deleted from the start, ignore
//        }
//
//        func didCreate(message: Message) {
//            add(message: message)
//        }
//    }
}
