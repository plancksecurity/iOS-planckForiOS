//
//  MessageSyncServiceTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 29.06.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

class MessageSyncServiceTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    var cdAccount: CdAccount!
    var cdAccountDisfunctional: CdAccount!
    var messageSyncService: MessageSyncService?

    class TestErrorDelegate: MessageSyncServiceErrorDelegate {
        var expErrorOccurred: XCTestExpectation?
        var error: Error?

        init(expErrorOccurred: XCTestExpectation? = nil) {
            self.expErrorOccurred = expErrorOccurred
        }

        func show(error: Error) {
            self.error = error
            if let expError = expErrorOccurred {
                expError.fulfill()
            } else {
                XCTFail("Send error: \(error)")
            }
        }
    }

    class TestSentDelegate: MessageSyncServiceSentDelegate {
        let expMessagesSent: XCTestExpectation?

        var requestedMessagesSent = Set<Message>()
        var messageIDsSent = Set<MessageID>()

        init(expMessagesSent: XCTestExpectation?) {
            self.expMessagesSent = expMessagesSent
        }

        func didSend(message: Message) {
            if requestedMessagesSent.contains(message) {
                XCTFail("message sent double")
            } else {
                requestedMessagesSent.insert(message)
            }
        }

        func didSend(messageIDs: [MessageID]) {
            messageIDsSent = messageIDsSent.union(messageIDs)
            expMessagesSent?.fulfill()
        }
    }

    class TestSyncDelegate: MessageSyncServiceSyncDelegate {
        let expMessagesSynced: XCTestExpectation

        init(expMessagesSynced: XCTestExpectation) {
            self.expMessagesSynced = expMessagesSynced
        }

        func didSync(account: Account) {
            expMessagesSynced.fulfill()
        }
    }

    class TestAccountVerificationDelegate: AccountVerificationServiceDelegate {
        let expAccountVerified: XCTestExpectation
        var verificationResult: AccountVerificationResult?

        init(expAccountVerified: XCTestExpectation) {
            self.expAccountVerified = expAccountVerified
        }

        func verified(account: Account, service: AccountVerificationServiceProtocol,
                      result: AccountVerificationResult) {
            self.verificationResult = result
            expAccountVerified.fulfill()
        }
    }

    class TestStateDelegate: MessageSyncServiceStateDelegate {
        let expReachedIdling: XCTestExpectation?

        init(expReachedIdling: XCTestExpectation?) {
            self.expReachedIdling = expReachedIdling
        }

        func startIdling(account: Account) {
            expReachedIdling?.fulfill()
        }
    }

    class MessageFolderTestDelegate: MessageFolderDelegate {
        let expMessagesDeleted: XCTestExpectation?
        var deletedMessages = Set<MessageFolder>()

        init(expMessagesDeleted: XCTestExpectation?) {
            self.expMessagesDeleted = expMessagesDeleted
        }

        func didChange(messageFolder: MessageFolder) {
            if messageFolder.isGhost {
                deletedMessages.insert(messageFolder)
            }
        }
    }

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        persistentSetup = PersistentSetup()

        let cdAccount = TestData().createWorkingCdAccount()
        cdAccount.identity?.isMySelf = true
        Record.saveAndWait()
        self.cdAccount = cdAccount
    }

    override func tearDown() {
        messageSyncService?.cancel()
        messageSyncService = nil
    }

    func send(messageSyncService ms: MessageSyncService, messages: [Message],
              numberOfTotalOutgoingMessages: Int, expectedNumberOfSyncs: Int) {
        let errorDelegate = TestErrorDelegate()
        ms.errorDelegate = errorDelegate

        var sentDelegate: TestSentDelegate?
        if numberOfTotalOutgoingMessages > 0 {
            let expMessagesSent = expectation(description: "expMessagesSent")
            expMessagesSent.expectedFulfillmentCount = UInt(expectedNumberOfSyncs)
            sentDelegate = TestSentDelegate(expMessagesSent: expMessagesSent)
            ms.sentDelegate = sentDelegate
        }

        let expMessagesSynced = expectation(description: "expMessagesSynced")
        expMessagesSynced.expectedFulfillmentCount = UInt(expectedNumberOfSyncs)
        let syncDelegate = TestSyncDelegate(expMessagesSynced: expMessagesSynced)
        ms.syncDelegate = syncDelegate

        let expReachedIdle = expectation(description: "expReachedIdle")
        expReachedIdle.expectedFulfillmentCount = UInt(expectedNumberOfSyncs)
        let stateDelegate = TestStateDelegate(expReachedIdling: expReachedIdle)
        ms.stateDelegate = stateDelegate

        ms.start(account: cdAccount.account())

        for msg in messages {
            ms.requestSend(message: msg)
        }

        waitForExpectations(timeout: TestUtil.waitTimeForever) { error in
            XCTAssertNil(error)
        }

        XCTAssertNil(errorDelegate.error)
        if let sd = sentDelegate {
            XCTAssertEqual(sd.requestedMessagesSent.count, messages.count)
            XCTAssertEqual(sd.messageIDsSent.count, numberOfTotalOutgoingMessages)
            for msg in messages {
                XCTAssertTrue(sd.messageIDsSent.contains(msg.messageID))
            }
        }
    }

    func runMessageSyncWithSend(ms: MessageSyncService,
                                cdAccount theCdAccount: CdAccount,
                                numberOfOutgoingMessagesToCreate: Int,
                                numberOfOutgoingMessagesToSendImmediately: Int,
                                numberOfOutgoingMessagesToSendLater: Int,
                                expectedNumberOfSyncs: Int) {
        let outgoingCdMsgs = TestUtil.createOutgoingMails(
            cdAccount: theCdAccount, testCase: self,
            numberOfMails: numberOfOutgoingMessagesToCreate)

        if outgoingCdMsgs.count < numberOfOutgoingMessagesToCreate {
            XCTFail()
            return
        }

        let cdMsgsToSend = outgoingCdMsgs.prefix(numberOfOutgoingMessagesToSendImmediately)
        XCTAssertEqual(cdMsgsToSend.count, numberOfOutgoingMessagesToSendImmediately)
        var msgsToSend = [Message]()
        for cdMsg in cdMsgsToSend {
            guard let msg = cdMsg.message() else {
                XCTFail()
                return
            }
            msgsToSend.append(msg)
        }

        send(messageSyncService: ms, messages: msgsToSend,
             numberOfTotalOutgoingMessages: outgoingCdMsgs.count,
             expectedNumberOfSyncs: expectedNumberOfSyncs)

        if numberOfOutgoingMessagesToSendLater <= 0 {
            return
        }

        let outgoingCdMsgs2 = TestUtil.createOutgoingMails(
            cdAccount: theCdAccount, testCase: self,
            numberOfMails: numberOfOutgoingMessagesToSendLater)
        if outgoingCdMsgs2.count < numberOfOutgoingMessagesToSendLater {
            XCTFail()
            return
        }
        let outgoingMessages = outgoingCdMsgs2.flatMap() { return $0.message() }
        send(messageSyncService: ms, messages: outgoingMessages,
             numberOfTotalOutgoingMessages: outgoingMessages.count, expectedNumberOfSyncs: 1)
    }

    func runMessageSyncServiceSend(parentName: String,
                                   cdAccount theCdAccount: CdAccount,
                                   numberOfOutgoingMessagesToCreate: Int,
                                   numberOfOutgoingMessagesToSendImmediately: Int,
                                   numberOfOutgoingMessagesToSendLater: Int,
                                   expectedNumberOfExpectedBackgroundTasks: Int,
                                   expectedNumberOfSyncs: Int) {
        var mbg: MockBackgrounder?
        if expectedNumberOfExpectedBackgroundTasks > 0 {
            let expBackgroundTaskFinished = expectation(description: "expBackgrounded")
            expBackgroundTaskFinished.expectedFulfillmentCount =
                UInt(expectedNumberOfExpectedBackgroundTasks)
            mbg = MockBackgrounder(expBackgroundTaskFinishedAtLeastOnce: expBackgroundTaskFinished)
        }
        let ms = MessageSyncService(
            sleepTimeInSeconds: 2, parentName: parentName, backgrounder: mbg, mySelfer: nil)
        messageSyncService = ms

        runMessageSyncWithSend(
            ms: ms, cdAccount: cdAccount,
            numberOfOutgoingMessagesToCreate: numberOfOutgoingMessagesToCreate,
            numberOfOutgoingMessagesToSendImmediately: numberOfOutgoingMessagesToSendImmediately,
            numberOfOutgoingMessagesToSendLater: numberOfOutgoingMessagesToSendLater,
            expectedNumberOfSyncs: expectedNumberOfSyncs)

        if let backgrounder = mbg {
            XCTAssertEqual(backgrounder.numberOfBackgroundTasksOutstanding, 0)
            XCTAssertEqual(backgrounder.totalNumberOfBackgroundTasksFinished,
                           expectedNumberOfExpectedBackgroundTasks)
            XCTAssertEqual(backgrounder.totalNumberOfBackgroundTasksStarted,
                           backgrounder.totalNumberOfBackgroundTasksFinished)
        }

        ms.cancel(account: cdAccount.account())
    }

    func testBasicPassiveSend() {
        runMessageSyncServiceSend(
            parentName: #function,
            cdAccount: cdAccount,
            numberOfOutgoingMessagesToCreate: 3,
            numberOfOutgoingMessagesToSendImmediately: 0,
            numberOfOutgoingMessagesToSendLater: 0,
            expectedNumberOfExpectedBackgroundTasks: 4,
            expectedNumberOfSyncs: 1)
    }

    func testSendSeveral() {
        runMessageSyncServiceSend(
            parentName: #function,
            cdAccount: cdAccount,
            numberOfOutgoingMessagesToCreate: 3,
            numberOfOutgoingMessagesToSendImmediately: 2,
            numberOfOutgoingMessagesToSendLater: 0,
            expectedNumberOfExpectedBackgroundTasks: 5,
            expectedNumberOfSyncs: 1)
    }

    func testSyncWithUnverifiedAccount() {
        let expMessagesSynced = expectation(description: "expMessagesSynced")
        let syncDelegate = TestSyncDelegate(expMessagesSynced: expMessagesSynced)

        let ms = MessageSyncService(
            sleepTimeInSeconds: 2, parentName: #function, backgrounder: nil, mySelfer: nil)
        messageSyncService = ms
        ms.syncDelegate = syncDelegate
        ms.start(account: cdAccount.account())

        waitForExpectations(timeout: TestUtil.waitTimeForever) { error in
            XCTAssertNil(error)
        }

        ms.cancel(account: cdAccount.account())
    }

    func testSyncWithErroneousAccount() {
        let expErrorOccurred = expectation(description: "expErrorOccurred")
        let errorDelegate = TestErrorDelegate(expErrorOccurred: expErrorOccurred)

        TestUtil.makeServersUnreachable(cdAccount: cdAccount)

        let ms = MessageSyncService(
            sleepTimeInSeconds: 2, parentName: #function, backgrounder: nil, mySelfer: nil)
        messageSyncService = ms
        ms.errorDelegate = errorDelegate
        ms.start(account: cdAccount.account())

        waitForExpectations(timeout: TestUtil.waitTimeForever) { error in
            XCTAssertNil(error)
        }

        XCTAssertNotNil(errorDelegate.error)

        ms.cancel(account: cdAccount.account())
    }

    func testTypicalNewAccountSetup() {
        let ms = MessageSyncService(
            sleepTimeInSeconds: 2, parentName: #function, backgrounder: nil, mySelfer: nil)
        messageSyncService = ms

        // Verification
        let expVerified = expectation(description: "expVerified")
        let verificationDelegate = TestAccountVerificationDelegate(expAccountVerified: expVerified)
        ms.requestVerification(account: cdAccount.account(), delegate: verificationDelegate)
        waitForExpectations(timeout: TestUtil.waitTimeForever) { error in
            XCTAssertNil(error)
        }
        guard let result = verificationDelegate.verificationResult else {
            XCTFail()
            return
        }
        switch result {
        case .ok:
            break
        default:
            XCTFail("Unexpected verification result: \(result)")
        }

        runMessageSyncWithSend(
            ms: ms, cdAccount: cdAccount, numberOfOutgoingMessagesToCreate: 3,
            numberOfOutgoingMessagesToSendImmediately: 3,
            numberOfOutgoingMessagesToSendLater: 0,
            expectedNumberOfSyncs: 1)

        ms.cancel(account: cdAccount.account())
    }

    func notestIdle() {
        let messageFolderDelegate = MessageFolderTestDelegate(expMessagesDeleted: nil)
        MessageModelConfig.messageFolderDelegate = messageFolderDelegate

        runMessageSyncServiceSend(
            parentName: #function,
            cdAccount: cdAccount,
            numberOfOutgoingMessagesToCreate: 0,
            numberOfOutgoingMessagesToSendImmediately: 0,
            numberOfOutgoingMessagesToSendLater: 0,
            expectedNumberOfExpectedBackgroundTasks: -1,
            expectedNumberOfSyncs: 2)

        print("Deleted messages: \(messageFolderDelegate.deletedMessages.count)")
    }
}
