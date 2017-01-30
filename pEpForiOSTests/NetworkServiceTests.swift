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
    }

    class NetworkServiceObserver: NetworkServiceDelegate, CustomDebugStringConvertible {
        let expSingleAccountSynced: XCTestExpectation?
        var expCanceled: XCTestExpectation?
        var accountInfo: AccountConnectInfo?

        var debugDescription: String {
            return expSingleAccountSynced?.debugDescription ?? "unknown"
        }

        init(expAccountsSynced: XCTestExpectation? = nil, expCanceled: XCTestExpectation? = nil) {
            self.expSingleAccountSynced = expAccountsSynced
            self.expCanceled = expCanceled
        }

        func didSync(service: NetworkService, accountInfo: AccountConnectInfo,
                     errorProtocol: ServiceErrorProtocol) {
            Log.info(component: #function, content: "\(self)")
            if errorProtocol.hasErrors() {
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
            return Array(messagesByID.values).sorted { m1, m2 in
                if let d1 = m1.received, let d2 = m2.received {
                    return areInIncreasingOrder(d1: d1, d2: d2)
                } else if let d1 = m1.sent, let d2 = m2.sent {
                    return areInIncreasingOrder(d1: d1, d2: d2)
                }
                return false
            }
        }
        var messagesByID = [MessageID: Message]()
        var changedMessagesByID = [MessageID: Message]()

        var hasChangedMessages: Bool {
            return !changedMessagesByID.isEmpty
        }

        func areInIncreasingOrder(d1: Date, d2: Date) -> Bool {
            switch d1.compare(d2 as Date) {
            case .orderedAscending: return true
            default: return false
            }
        }

        func didChange(messageFolder: MessageFolder) {
            if let msg = messageFolder as? Message {
                if msg.isOriginal {
                    messagesByID[msg.messageID] = msg
                } else {
                    XCTAssertNotNil(messagesByID[msg.messageID])
                    messagesByID[msg.messageID] = msg
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

        func didVerify(cdAccount: CdAccount, error: NSError?) {
            XCTAssertNil(error)
            expAccountVerified?.fulfill()
        }

        func didFetchMessage(messageID: String) {
            if let msg = Message.byMessageID(messageID) {
                MessageModelConfig.messageFolderDelegate?.didChange(messageFolder: msg)
                if !msg.isGhost {
                    messageIDs.append(messageID)
                }
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

    func testSyncOutgoing() {
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
            expAccountsSynced: expectation(description: "expSingleAccountSynced1"))

        networkService.networkServiceDelegate = del
        networkService.sendLayerDelegate = sendLayerDelegate

        let cdAccount = TestData().createWorkingCdAccount()
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

        let folder = CdFolder.by(folderType: .sent, account: cdAccount)
        XCTAssertNotNil(folder)
        XCTAssertEqual((folder?.messages ?? NSSet()).count, 0)

        // Build outgoing emails
        var outgoingMails = [CdMessage]()
        var outgoingMessageIDs = [String]()
        let numMails = 5
        for i in 1...numMails {
            let message = CdMessage.create()
            message.from = from
            message.parent = folder
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
        for m in outgoingMails {
            XCTAssertTrue(m.isDeleted)
        }

        guard let sentFolder = CdFolder.by(folderType: .sent, account: cdAccount) else {
            XCTFail()
            cancelNetworkService(networkService: networkService)
            return
        }

        // Make sure the sent folder will still *not* be synced in the next step
        sentFolder.lastLookedAt = Date(
            timeIntervalSinceNow: -(networkService.timeIntervalForInterestingFolders + 1))
            as NSDate?
        Record.saveAndWait()

        // Will the sent folder be synced on next sync?
        let accountInfo = AccountConnectInfo(accountID: cdAccount.objectID)
        var fis = networkService.determineInterestingFolders(accountInfo: accountInfo)
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
        fis = networkService.determineInterestingFolders(accountInfo: accountInfo)
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

        for msgID in outgoingMessageIDs {
            guard let cdMsg = CdMessage.first(attributes: ["uuid": msgID]) else {
                XCTFail()
                continue
            }
            XCTAssertGreaterThan(cdMsg.uid, 0)
        }

        cancelNetworkService(networkService: networkService)
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

        guard let cdFolder = CdFolder.first(attributes: ["folderType": FolderType.inbox.rawValue]) else {
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

        var decryptAgainCount = 0
        let unifiedInbox = Folder.unifiedInbox()
        let mc = unifiedInbox.messageCount()
        XCTAssertGreaterThan(mc, 0)
        for i in 0..<mc {
            let msg = unifiedInbox.messageAt(index: i)
            XCTAssertNotNil(msg?.shortMessage)
            XCTAssertTrue(
                msg?.longMessage != nil || msg?.longMessageFormatted != nil ||
                    (msg?.attachments.count ?? 0) > 0)
            guard let pEpRating = msg?.pEpRatingInt else {
                XCTFail()
                continue
            }
            if pEpRating == Int(PEPUtil.pEpRatingNone) {
                decryptAgainCount += 1
            }
        }
        XCTAssertEqual(cdDecryptAgainCount, decryptAgainCount)

        let inbox = Folder.from(cdFolder: cdFolder)
        XCTAssertEqual(sendLayerDelegate.messageIDs.count, mc)
        XCTAssertEqual(modelDelegate.messages.count, mc)
        for msg in modelDelegate.messages {
            XCTAssertTrue(msg.isOriginal)
            XCTAssertTrue(sendLayerDelegate.messageIDs.contains(msg.messageID))
            XCTAssertTrue(inbox.contains(message: msg))
            XCTAssertTrue(unifiedInbox.contains(message: msg))
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

    func testCdAccountVerification() {
        XCTAssertNil(CdAccount.all())
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let networkService = NetworkService(parentName: #function)

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"))
        networkService.networkServiceDelegate = del

        let expAccountVerified = expectation(description: "expAccountVerified")
        let sendLayerDelegate = SendLayerObserver(expAccountVerified: expAccountVerified)
        networkService.sendLayerDelegate = sendLayerDelegate

        let cdAccount = TestData().createWorkingCdAccount()
        Record.saveAndWait()

        XCTAssertTrue(cdAccount.needsVerification)
        guard let creds = cdAccount.credentials?.array as? [CdServerCredentials] else {
            XCTFail()
            return
        }
        for cr in creds {
            XCTAssertTrue(cr.needsVerification)
        }

        networkService.verify(cdAccount: cdAccount)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertNotNil(CdFolder.all())
        XCTAssertNotNil(CdMessage.all())

        Record.Context.default.refresh(cdAccount, mergeChanges: true)
        XCTAssertFalse(cdAccount.needsVerification)
        for cr in creds {
            Record.Context.default.refresh(cr, mergeChanges: true)
            XCTAssertFalse(cr.needsVerification)
        }

        cancelNetworkService(networkService: networkService)
    }

    class AccountObserver: AccountDelegate {
        let expAccountVerified: XCTestExpectation?
        var account: Account?

        init(expAccountVerified: XCTestExpectation?) {
            self.expAccountVerified = expAccountVerified
        }

        func didVerify(account: Account, error: NSError?) {
            XCTAssertNil(error)
            expAccountVerified?.fulfill()
            self.account = account
        }
    }

    class Backgrounder: BackgroundTaskProtocol {
        let expBackgrounded: XCTestExpectation?
        let taskName: String?
        let taskID = 1

        init(taskName: String? = nil, expBackgrounded: XCTestExpectation? = nil) {
            self.expBackgrounded = expBackgrounded
            self.taskName = taskName
        }

        func beginBackgroundTask(taskName: String?,
                                 expirationHandler: (() -> Void)?) -> BackgroundTaskID {
            XCTAssertEqual(taskName, self.taskName)
            return taskID
        }

        func endBackgroundTask(_ taskID: BackgroundTaskID?) {
            XCTAssertEqual(taskID, taskID)
            expBackgrounded?.fulfill()
        }
    }

    class MySelfObserver: KickOffMySelfProtocol {
        let expMySelfed: XCTestExpectation?
        let queue = LimitedOperationQueue()
        let backgrounder: Backgrounder

        init(expMySelfed: XCTestExpectation?, expBackgrounded: XCTestExpectation?) {
            self.expMySelfed = expMySelfed
            backgrounder = Backgrounder(
                taskName: "MySelfOperation", expBackgrounded: expBackgrounded)
        }

        func startMySelf() {
            let op = MySelfOperation(backgrounder: backgrounder)
            op.completionBlock = {
                self.expMySelfed?.fulfill()
            }
            queue.addOperation(op)
        }
    }

    func testAccountVerification() {
        XCTAssertTrue(Account.all().isEmpty)

        let mySelfObserver = MySelfObserver(
            expMySelfed: expectation(description: "expMySelfed"),
            expBackgrounded: expectation(description: "expBackgrounded"))

        let networkService = NetworkService(parentName: #function, mySelfer: mySelfObserver)

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"))
        networkService.networkServiceDelegate = del

        CdAccount.sendLayer = networkService

        let accountObserver = AccountObserver(
            expAccountVerified: expectation(description: "expAccountVerified"))
        MessageModelConfig.accountDelegate = accountObserver

        let account = TestData().createWorkingAccount()

        XCTAssertTrue(account.needsVerification)
        for cr in account.serverCredentials {
            XCTAssertTrue(cr.needsVerification)
        }

        waitForExpectations(timeout: TestUtil.waitTime * 2, handler: { error in
            XCTAssertNil(error)
        })

        guard let verifiedAccount = accountObserver.account else {
            XCTFail()
            return
        }

        guard let cdAccount = CdAccount.first() else {
            XCTFail()
            return
        }
        XCTAssertFalse(cdAccount.needsVerification)

        XCTAssertFalse(verifiedAccount.needsVerification)
        for cr in verifiedAccount.serverCredentials {
            XCTAssertFalse(cr.needsVerification)
        }

        XCTAssertFalse(verifiedAccount.rootFolders.isEmpty)
        let inbox = verifiedAccount.inbox()
        XCTAssertNotNil(inbox)
        if let inb = inbox {
            XCTAssertGreaterThan(inb.messageCount(), 0)
        }

        cancelNetworkService(networkService: networkService)
    }

    func _testRunForever() {
        XCTAssertTrue(Account.all().isEmpty)

        let mySelfObserver = MySelfObserver(
            expMySelfed: expectation(description: "expMySelfed"),
            expBackgrounded: expectation(description: "expBackgrounded"))

        let networkService = NetworkService(parentName: #function, mySelfer: mySelfObserver)

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"))
        networkService.networkServiceDelegate = del

        networkService.start()

        CdAccount.sendLayer = networkService

        let accountObserver = AccountObserver(
            expAccountVerified: expectation(description: "expAccountVerified"))
        MessageModelConfig.accountDelegate = accountObserver

        let account = TestData().createWorkingAccount()

        XCTAssertTrue(account.needsVerification)
        for cr in account.serverCredentials {
            XCTAssertTrue(cr.needsVerification)
        }

        waitForExpectations(timeout: TestUtil.waitTimeForever, handler: { error in
            XCTAssertNil(error)
        })

        guard let verifiedAccount = accountObserver.account else {
            XCTFail()
            return
        }

        guard let cdAccount = CdAccount.first() else {
            XCTFail()
            return
        }
        XCTAssertFalse(cdAccount.needsVerification)

        XCTAssertFalse(verifiedAccount.needsVerification)
        for cr in verifiedAccount.serverCredentials {
            XCTAssertFalse(cr.needsVerification)
        }

        XCTAssertFalse(verifiedAccount.rootFolders.isEmpty)
        let inbox = verifiedAccount.inbox()
        XCTAssertNotNil(inbox)
        if let inb = inbox {
            XCTAssertGreaterThan(inb.messageCount(), 0)
        }

        // Wait a long time, just let it sync over and over again
        let _ = expectation(description: "expForever")
        waitForExpectations(timeout: TestUtil.waitTimeForever, handler: { error in
            XCTAssertNil(error)
        })
    }
}
