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

    class NetworkServiceObserver: NetworkServiceDelegate {
        let expSingleAccountSynced: XCTestExpectation?
        var expCanceled: XCTestExpectation?
        var accountInfo: AccountConnectInfo?

        init(expAccountsSynced: XCTestExpectation? = nil, expCanceled: XCTestExpectation? = nil) {
            self.expSingleAccountSynced = expAccountsSynced
            self.expCanceled = expCanceled
        }

        func didSync(service: NetworkService, accountInfo: AccountConnectInfo) {
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
        var messages = [Message]()

        func didChange(messageFolder: MessageFolder) {
            if let msg = messageFolder as? Message {
                messages.append(msg)
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
            messageIDs.append(messageID)
            if let msg = Message.byUUID(messageID) {
                MessageModelConfig.messageFolderDelegate?.didChange(messageFolder: msg)
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

    func testSyncOneTime() {
        XCTAssertNil(CdAccount.all())
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let modelDelegate = MessageModelObserver()
        MessageModelConfig.messageFolderDelegate = modelDelegate

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"))

        let sendLayerDelegate = SendLayerObserver()

        let networkService = NetworkService(parentName: #function)
        networkService.networkServiceDelegate = del
        networkService.sendLayerDelegate = sendLayerDelegate

        _ = TestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()

        networkService.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        networkService.cancel()
        XCTAssertNotNil(del.accountInfo)
        XCTAssertNotNil(CdFolder.all())
        XCTAssertNotNil(CdMessage.all())

        guard let cdFolder = CdFolder.first(with: ["folderType": FolderType.inbox.rawValue]) else {
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
    }

    func testCancelSync() {
        XCTAssertNil(CdAccount.all())
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"),
            expCanceled: expectation(description: "expCanceled"))

        let networkService = NetworkService(parentName: #function)
        networkService.networkServiceDelegate = del

        _ = TestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()

        networkService.start()
        networkService.cancel()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())
    }

    func testCdAccountVerification() {
        XCTAssertNil(CdAccount.all())
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"))
        let networkService = NetworkService(parentName: #function)
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

        del.expCanceled = expectation(description: "expCanceled")
        networkService.cancel()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
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

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"))
        let networkService = NetworkService(parentName: #function, mySelfer: mySelfObserver)
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

        XCTAssertNotNil(cdAccount.identity?.fingerPrint)

        del.expCanceled = expectation(description: "expCanceled")
        networkService.cancel()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func ttestRunForever() {
        XCTAssertTrue(Account.all().isEmpty)

        let mySelfObserver = MySelfObserver(
            expMySelfed: expectation(description: "expMySelfed"),
            expBackgrounded: expectation(description: "expBackgrounded"))

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"))
        let networkService = NetworkService(parentName: #function, mySelfer: mySelfObserver)
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

        XCTAssertNotNil(cdAccount.identity?.fingerPrint)

        // Wait a long time, just let it sync over and over again
        let _ = expectation(description: "expForever")
        waitForExpectations(timeout: TestUtil.waitTimeForever, handler: { error in
            XCTAssertNil(error)
        })
    }
}
