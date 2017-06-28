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

    class NetworkServiceObserver: NetworkServiceDelegate, CustomDebugStringConvertible {
        let expSingleAccountSynced: XCTestExpectation?
        var expCanceled: XCTestExpectation?
        var accountInfo: AccountConnectInfo?

        var debugDescription: String {
            return expSingleAccountSynced?.debugDescription ?? "unknown"
        }

        let failOnError: Bool

        init(expAccountsSynced: XCTestExpectation? = nil, expCanceled: XCTestExpectation? = nil,
             failOnError: Bool = false) {
            self.expSingleAccountSynced = expAccountsSynced
            self.expCanceled = expCanceled
            self.failOnError = failOnError
        }

        func didSync(service: NetworkService, accountInfo: AccountConnectInfo,
                     errorProtocol: ServiceErrorProtocol) {
            Log.info(component: #function, content: "\(self)")
            if errorProtocol.hasErrors() && failOnError {
                Log.error(component: #function, error: errorProtocol.error)
                XCTFail()
            }
            if self.accountInfo == nil {
                self.accountInfo = accountInfo
                expSingleAccountSynced?.fulfill()
            }
        }

        func didCancel(service: NetworkService) {
            expCanceled?.fulfill()
        }
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

        func didChange(messageFolder: MessageFolder) {
            if let msg = messageFolder as? Message {
                if msg.isOriginal {
                    add(message: msg)
                } else {
                    XCTAssertNotNil(messagesByID[msg.messageID])
                    add(message: msg)
                    changedMessagesByID[msg.messageID] = msg
                }
            }
        }
    }

    class SendLayerObserver: SendLayerDelegate {
        let expAccountVerified: XCTestExpectation?
        var messageIDs = [String]()

        init(expAccountVerified: XCTestExpectation? = nil) {
            self.expAccountVerified = expAccountVerified
        }

        func didVerify(cdAccount: CdAccount, error: Error?) {
            XCTAssertNil(error)
            expAccountVerified?.fulfill()
        }

        func didFetch(cdMessage: CdMessage) {
            if let msg = cdMessage.message() {
                messageIDs.append(msg.messageID)
            } else {
                XCTFail()
            }
        }

        func didRemove(cdFolder: CdFolder) {
            XCTFail()
        }

        func didRemove(cdMessage: CdMessage) {
            XCTFail()
        }
    }

    func testSyncOutgoing(useCorrectSmtpAccount: Bool) {
        XCTAssertNil(CdAccount.all())
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let modelDelegate = MessageModelObserver()
        MessageModelConfig.messageFolderDelegate = modelDelegate

        let sendLayerDelegate = SendLayerObserver()

        let networkService = NetworkService(parentName: #function)
        networkService.sleepTimeInSeconds = 2

        // A temp variable is necassary, since the networkServiceDelegate is weak
        var del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced1"),
            failOnError: useCorrectSmtpAccount)

        networkService.networkServiceDelegate = del
        networkService.sendLayerDelegate = sendLayerDelegate

        let cdAccount = useCorrectSmtpAccount ? TestData().createWorkingCdAccount() :
            TestData().createSmtpTimeOutCdAccount()
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

        // Build outgoing emails
        var outgoingMails = [CdMessage]()
        var outgoingMessageIDs = [String]()
        let numMails = 5
        for i in 1...numMails {
            let message = CdMessage.create()
            message.from = from
            message.parent = sentFolder
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.addTo(cdIdentity: to)
            let messageID = MessageID.generate()
            message.uuid = messageID
            outgoingMails.append(message)
            outgoingMessageIDs.append(messageID)
        }
        Record.saveAndWait()

        // Verify outgoing mails
        for m in outgoingMails {
            XCTAssertEqual(m.parent?.folderType, FolderType.sent.rawValue)
            XCTAssertEqual(m.uid, Int32(0))
            XCTAssertEqual(m.sendStatus, Int16(SendStatus.none.rawValue))
        }

        del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced2"))
        networkService.networkServiceDelegate = del

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
            as NSDate?
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
        sentFolder.lastLookedAt = Date() as NSDate?
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
        networkService.networkServiceDelegate = del

        // Wait for next sync
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            Log.info(component: "didSync", content: "expSingleAccountSynced3 timeout?")
            XCTAssertNil(error)
        })

        TestUtil.checkForUniqueness(uuids: outgoingMessageIDs)
        cancelNetworkService(networkService: networkService)
    }

    func testSyncOutgoing() {
        testSyncOutgoing(useCorrectSmtpAccount: true)
    }

    func testSyncOutgoingWithWrongAccount() {
        testSyncOutgoing(useCorrectSmtpAccount: false)
    }

    func cancelNetworkService(networkService: NetworkService) {
        let del = NetworkServiceObserver(
            expCanceled: expectation(description: "expCanceled"))
        networkService.networkServiceDelegate = del
        networkService.cancel()

        // Wait for cancellation
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
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
        networkService.networkServiceDelegate = del

        networkService.sendLayerDelegate = sendLayerDelegate

        _ = TestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()

        networkService.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertNotNil(del.accountInfo)
        XCTAssertNotNil(CdFolder.all())
        XCTAssertNotNil(CdMessage.all())

        guard let cdFolder = CdFolder.first(
            attributes: ["folderType": FolderType.inbox.rawValue]) else {
                XCTFail()
                return
        }
        XCTAssertGreaterThan(cdFolder.messages?.count ?? 0, 0)
        let allCdMessages = cdFolder.messages?.sortedArray(
            using: [NSSortDescriptor(key: "uid", ascending: true)]) as? [CdMessage] ?? []
        XCTAssertGreaterThan(allCdMessages.count, 0)
        var cdDecryptAgainCount = 0
        for cdMsg in allCdMessages {
            guard let parentF = cdMsg.parent else {
                XCTFail()
                continue
            }
            XCTAssertEqual(parentF.folderType, FolderType.inbox.rawValue)
            if cdMsg.pEpRating == PEPUtil.pEpRatingNone {
                cdDecryptAgainCount += 1
            }
        }
        XCTAssertGreaterThan(allCdMessages.count, cdDecryptAgainCount)

        let unifiedInbox = Folder.unifiedInbox()

        let unifiedMessageCount = unifiedInbox.messageCount()
        XCTAssertGreaterThan(unifiedMessageCount, 0)
        for i in 0..<unifiedMessageCount {
            guard let msg = unifiedInbox.messageAt(index: i) else {
                XCTFail()
                continue
            }
            XCTAssertNotNil(msg.shortMessage)
            XCTAssertTrue(
                msg.longMessage != nil || msg.longMessageFormatted != nil ||
                    msg.attachments.count > 0)
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
            XCTAssertTrue(msg.isOriginal)
            XCTAssertTrue(sendLayerDelegate.messageIDs.contains(msg.messageID))
            XCTAssertTrue(inbox.contains(message: msg))
            if !unifiedInbox.contains(message: msg) {
                XCTFail()
            }
        }
        XCTAssertFalse(modelDelegate.hasChangedMessages)

        cancelNetworkService(networkService: networkService)
    }

    func testCancelSyncImmediately() {
        XCTAssertNil(CdAccount.all())
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let networkService = NetworkService(parentName: #function)

        _ = TestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()

        for _ in 0...10 {
            networkService.start()
            cancelNetworkService(networkService: networkService)
        }

        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())
    }

    class MySelfObserver: KickOffMySelfProtocol {
        let expMySelfed: XCTestExpectation?
        let queue = LimitedOperationQueue()
        let backgrounder: MockBackgrounder

        init(expMySelfed: XCTestExpectation?, expBackgrounded: XCTestExpectation?) {
            self.expMySelfed = expMySelfed
            backgrounder = MockBackgrounder(expBackgrounded: expBackgrounded)
        }

        func startMySelf() {
            let op = MySelfOperation(backgrounder: backgrounder)
            op.completionBlock = {
                self.expMySelfed?.fulfill()
            }
            queue.addOperation(op)
        }
    }
}
