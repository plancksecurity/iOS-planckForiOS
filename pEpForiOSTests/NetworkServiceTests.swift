//
//  NetworkServiceTests.swift
//  pEpForiOS
//
//  Created by hernani on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel
import pEpForiOS

class NetworkServiceTests: XCTestCase {
    var persistenceSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistenceSetup = PersistentSetup()
    }

    override func tearDown() {
        persistenceSetup = nil
        CdAccount.sendLayer = nil
        super.tearDown()
    }

    class MessageModelObserver: MessageFolderDelegate {
        var messages: [Message] {
            var messages = [Message]()
            for ms in messagesByID.values {
                for m in ms {
                    messages.append(m)
                }
            }
            return messages.sorted { m1, m2 in
                if let d1 = m1.received, let d2 = m2.received {
                    return areInIncreasingOrder(d1: d1, d2: d2)
                } else if let d1 = m1.sent, let d2 = m2.sent {
                    return areInIncreasingOrder(d1: d1, d2: d2)
                }
                return false
            }
        }
        var messagesByID = [MessageID: [Message]]()
        var changedMessagesByID = [MessageID: Message]()

        var hasChangedMessages: Bool {
            return !changedMessagesByID.isEmpty
        }

        func contains(messageID: MessageID) -> Bool {
            return messagesByID[messageID] != nil
        }

        func areInIncreasingOrder(d1: Date, d2: Date) -> Bool {
            switch d1.compare(d2 as Date) {
            case .orderedAscending: return true
            default: return false
            }
        }

        func add(message: Message) {
            if let existing = messagesByID[message.uuid] {
                var news = existing
                news.append(message)
                messagesByID[message.uuid] = news
            } else {
                messagesByID[message.uuid] = [message]
            }
        }
        
        func didUpdate(messageFolder: MessageFolder) {
            if let msg = messageFolder as? Message {
                // messages has been changed during the test
                XCTAssertNotNil(messagesByID[msg.messageID])
                add(message: msg)
                changedMessagesByID[msg.messageID] = msg
            }
        }
        func didDelete(messageFolder: MessageFolder) {
            // this message has been deleted from the start, ignore
        }
        func didCreate(messageFolder: MessageFolder) {
            if let msg = messageFolder as? Message {
                add(message: msg)
            }
        }
    }

    func testSyncOutgoing() {
        testSyncOutgoing(useCorrectSmtpAccount: true)
    }

    func testSyncOutgoingWithWrongAccount() {
        testSyncOutgoing(useCorrectSmtpAccount: false)
    }

    func testSyncOneTime() {
        XCTAssertNil(CdAccount.all())
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let modelDelegate = MessageModelObserver()
        MessageModelConfig.messageFolderDelegate = modelDelegate

        let sendLayerDelegate = SendLayerObserver()

        let networkService = NetworkService(parentName: #function)

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"))
        networkService.unitTestDelegate = del

        networkService.sendLayerDelegate = sendLayerDelegate

        _ = SecretTestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()

        networkService.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertNotNil(del.accountInfo)
        XCTAssertNotNil(CdFolder.all())

        guard let cdFolder = CdFolder.first(
            attributes: ["folderTypeRawValue": FolderType.inbox.rawValue]) else {
                XCTFail()
                return
        }
        XCTAssertGreaterThanOrEqual(cdFolder.messages?.count ?? 0, 0)
        let allCdMessages = cdFolder.messages?.sortedArray(
            using: [NSSortDescriptor(key: "uid", ascending: true)]) as? [CdMessage] ?? []
        XCTAssertGreaterThanOrEqual(allCdMessages.count, 0)

        for cdMsg in allCdMessages {
            guard let parentF = cdMsg.parent else {
                XCTFail()
                continue
            }
            XCTAssertEqual(parentF.folderType, FolderType.inbox)
        }

        let unifiedInbox = UnifiedInbox()

        let unifiedMessageCount = unifiedInbox.messageCount()
        XCTAssertGreaterThanOrEqual(unifiedMessageCount, 0)
        for i in 0..<unifiedMessageCount {
            guard let msg = unifiedInbox.messageAt(index: i) else {
                XCTFail()
                continue
            }

            XCTAssertTrue(msg.isValidMessage())

            let pEpRating = Int16(msg.pEpRatingInt ?? -1)
            XCTAssertNotEqual(pEpRating, PEPUtil.pEpRatingNone)
            if !modelDelegate.contains(messageID: msg.messageID) {
                XCTFail()
            }
        }

        let inbox = Folder.from(cdFolder: cdFolder)
        XCTAssertGreaterThanOrEqual(sendLayerDelegate.messageIDs.count, unifiedMessageCount)
        XCTAssertEqual(modelDelegate.messages.count, unifiedMessageCount)

        for msg in modelDelegate.messages {
            let msgIsFlaggedDeleted = msg.imapFlags?.deleted ?? false
            XCTAssertTrue(!msgIsFlaggedDeleted)
            XCTAssertTrue(sendLayerDelegate.messageIDs.contains(msg.messageID))
            XCTAssertTrue(inbox.contains(message: msg))
            if !unifiedInbox.contains(message: msg) {
                XCTFail()
            }
        }
        XCTAssertFalse(modelDelegate.hasChangedMessages)

        TestUtil.cancelNetworkService(networkService: networkService, testCase: self)
    }

    func testCancelSyncImmediately() {
        XCTAssertNil(CdAccount.all())
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let networkService = NetworkService(parentName: #function)

        _ = SecretTestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()

        for _ in 0...10 {
            networkService.start()
            TestUtil.cancelNetworkService(networkService: networkService, testCase: self)
        }

        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())
    }

    class MySelfObserver: KickOffMySelfProtocol {
        let expMySelfed: XCTestExpectation?
        let queue = LimitedOperationQueue()
        let backgrounder: MockBackgrounder

        init(expMySelfed: XCTestExpectation?,
             expBackgroundTaskFinishedAtLeastOnce: XCTestExpectation?) {
            self.expMySelfed = expMySelfed
            backgrounder = MockBackgrounder(
                expBackgroundTaskFinishedAtLeastOnce: expBackgroundTaskFinishedAtLeastOnce)
        }

        func startMySelf() {
            let op = MySelfOperation(parentName: #function, backgrounder: backgrounder)
            op.completionBlock = {
                op.completionBlock = nil
                self.expMySelfed?.fulfill()
            }
            queue.addOperation(op)
        }
    }

    //MARK: HELPER

    func testSyncOutgoing(useCorrectSmtpAccount: Bool) {
        XCTAssertNil(CdAccount.all())
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let modelDelegate = MessageModelObserver()
        MessageModelConfig.messageFolderDelegate = modelDelegate

        let sendLayerDelegate = SendLayerObserver()

        let networkService = NetworkService(parentName: #function)
        networkService.sleepTimeInSeconds = 2

        // A temp variable is necassary, since the networkServiceUnitTestDelegate is weak
        let expAccountsSynced = expectation(description: "expSingleAccountSynced1")
        var del = NetworkServiceObserver(
            expAccountsSynced: expAccountsSynced,
            failOnError: useCorrectSmtpAccount)

        networkService.unitTestDelegate = del
        networkService.sendLayerDelegate = sendLayerDelegate

        let cdAccount = useCorrectSmtpAccount ? SecretTestData().createWorkingCdAccount() :
            SecretTestData().createSmtpTimeOutCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()

        networkService.start()

        // Wait for first sync, mainly to have folders
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        let from = CdIdentity.create()
        from.userName = cdAccount.identity?.userName ?? "Unit 004"
        from.address = cdAccount.identity?.address ?? "unittest.ios.4@peptest.ch"

        let to = CdIdentity.create()
        to.userName = "Unit 001"
        to.address = "unittest.ios.1@peptest.ch"

        guard let sentFolder = CdFolder.by(folderType: .sent, account: cdAccount) else {
            XCTFail()
            return
        }
        XCTAssertEqual((sentFolder.messages ?? NSSet()).count, 0)

        let numMails = 1
        let outgoingMails = TestUtil.createOutgoingMails(cdAccount: cdAccount,
                                                         testCase: self, numberOfMails: numMails)
        let outgoingMessageIDs: [String] = outgoingMails
            .map() { $0.messageID ?? "" }
            .filter() { $0 != "" }

        // Verify outgoing mails
        for m in outgoingMails {
            XCTAssertEqual(m.parent?.folderType, FolderType.sent)
            XCTAssertEqual(m.uid, Int32(0))
            XCTAssertEqual(m.sendStatus, SendStatus.none)
        }

        let expAccountsSynced2 = expectation(description: "expSingleAccountSynced2")
        del = NetworkServiceObserver(
            expAccountsSynced: expAccountsSynced2)
        networkService.unitTestDelegate = del

        // Wait for next sync, to verify outgoing mails
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        // Check that the sent mails have been deleted
        Record.refreshRegisteredObjects(mergeChanges: true)
        if useCorrectSmtpAccount {
            for m in outgoingMails {
                XCTAssertTrue(m.isDeleted)
            }
        }

        // Make sure the sent folder will still *not* be synced in the next step
        sentFolder.lastLookedAt = Date(
            timeIntervalSinceNow: -(networkService.timeIntervalForInterestingFolders + 1))
        Record.saveAndWait()

        // Will the sent folder be synced on next sync?
        let accountInfo = AccountConnectInfo(accountID: cdAccount.objectID)
        var fis = networkService.currentWorker?.determineInterestingFolders(
            accountInfo: accountInfo) ?? []
        XCTAssertEqual(fis.count, 1) // still only inbox

        var haveSentFolder = false
        for f in fis {
            if f.folderType == .sent {
                haveSentFolder = true
            }
        }
        XCTAssertFalse(haveSentFolder)

        // Make sure the sent folder will be synced in the next step
        sentFolder.lastLookedAt = Date()
        Record.saveAndWait()

        // Will the sent folder be synced on next sync?
        fis = networkService.currentWorker?.determineInterestingFolders(
            accountInfo: accountInfo) ?? []
        XCTAssertGreaterThan(fis.count, 1)

        for f in fis {
            if f.folderType == .sent {
                haveSentFolder = true
            }
        }
        XCTAssertTrue(haveSentFolder)

        del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced3"))
        networkService.unitTestDelegate = del
        
        // Wait for next sync
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            Log.info(component: "didSync", content: "expSingleAccountSynced3 timeout?")
            XCTAssertNil(error)
        })

        if useCorrectSmtpAccount {
            // those messages do not exist if we are using an incorrect account
            TestUtil.checkForExistanceAndUniqueness(uuids: outgoingMessageIDs)
        }
        TestUtil.cancelNetworkService(networkService: networkService, testCase: self)
    }
}
