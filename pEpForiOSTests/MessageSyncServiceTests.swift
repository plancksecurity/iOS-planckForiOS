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
        let expMessagesSent: XCTestExpectation

        var requestedMessagesSent = Set<Message>()
        var messageIDsSent = Set<MessageID>()

        init(expMessagesSent: XCTestExpectation) {
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
            expMessagesSent.fulfill()
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

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        persistentSetup = PersistentSetup()

        let cdAccount = TestData().createWorkingCdAccount()
        cdAccount.identity?.isMySelf = true
        Record.saveAndWait()
        self.cdAccount = cdAccount
    }

    func send(messageSyncService ms: MessageSyncService, messages: [Message],
              numberOfTotalOutgoingMessages: Int) {
        let errorDelegate = TestErrorDelegate()
        ms.errorDelegate = errorDelegate

        let expMessagesSent = expectation(description: "expMessagesSent")
        let sentDelegate = TestSentDelegate(expMessagesSent: expMessagesSent)
        ms.sentDelegate = sentDelegate

        let expMessagesSynced = expectation(description: "expMessagesSynced")
        let syncDelegate = TestSyncDelegate(expMessagesSynced: expMessagesSynced)
        ms.syncDelegate = syncDelegate

        let expReachedIdle = expectation(description: "expReachedIdle")
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
        XCTAssertEqual(sentDelegate.requestedMessagesSent.count, messages.count)
        XCTAssertEqual(sentDelegate.messageIDsSent.count, numberOfTotalOutgoingMessages)

        for msg in messages {
            XCTAssertTrue(sentDelegate.messageIDsSent.contains(msg.messageID))
        }
    }

    func runMessageSyncWithSend(ms: MessageSyncService,
                                cdAccount theCdAccount: CdAccount,
                                numberOfOutgoingMessagesToCreate: Int,
                                numberOfOutgoingMessagesToSendImmediately: Int,
                                numberOfOutgoingMessagesToSendLater: Int) {
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
             numberOfTotalOutgoingMessages: outgoingCdMsgs.count)

        if numberOfOutgoingMessagesToSendLater <= 0 {
            return
        }
    }

    func runMessageSyncServiceSend(cdAccount theCdAccount: CdAccount,
                                   numberOfOutgoingMessagesToCreate: Int,
                                   numberOfOutgoingMessagesToSendImmediately: Int,
                                   numberOfOutgoingMessagesToSendLater: Int,
                                   expectedNumberOfExpectedBackgroundTasks: Int) {

        let expBackgroundTaskFinished = expectation(description: "expBackgrounded")
        expBackgroundTaskFinished.expectedFulfillmentCount =
            UInt(expectedNumberOfExpectedBackgroundTasks)
        let mbg = MockBackgrounder(expBackgroundTaskFinishedAtLeastOnce: expBackgroundTaskFinished)
        let ms = MessageSyncService(
            sleepTimeInSeconds: 2, parentName: #function, backgrounder: mbg, mySelfer: nil)

        runMessageSyncWithSend(
            ms: ms, cdAccount: cdAccount,
            numberOfOutgoingMessagesToCreate: numberOfOutgoingMessagesToCreate,
            numberOfOutgoingMessagesToSendImmediately: numberOfOutgoingMessagesToSendImmediately,
            numberOfOutgoingMessagesToSendLater: numberOfOutgoingMessagesToSendLater)

        XCTAssertEqual(mbg.numberOfBackgroundTasksOutstanding, 0)
        XCTAssertEqual(mbg.totalNumberOfBackgroundTasksFinished,
                       expectedNumberOfExpectedBackgroundTasks)
        XCTAssertEqual(mbg.totalNumberOfBackgroundTasksStarted,
                       mbg.totalNumberOfBackgroundTasksFinished)
    }

    func testBasicPassiveSend() {
        runMessageSyncServiceSend(
            cdAccount: cdAccount,
            numberOfOutgoingMessagesToCreate: 3,
            numberOfOutgoingMessagesToSendImmediately: 0,
            numberOfOutgoingMessagesToSendLater: 0,
            expectedNumberOfExpectedBackgroundTasks: 4)
    }

    func testSendSeveral() {
        runMessageSyncServiceSend(
            cdAccount: cdAccount,
            numberOfOutgoingMessagesToCreate: 3,
            numberOfOutgoingMessagesToSendImmediately: 2,
            numberOfOutgoingMessagesToSendLater: 0,
            expectedNumberOfExpectedBackgroundTasks: 5)
    }

    func testSyncWithUnverifiedAccount() {
        let expMessagesSynced = expectation(description: "expMessagesSynced")
        let syncDelegate = TestSyncDelegate(expMessagesSynced: expMessagesSynced)

        let ms = MessageSyncService(
            sleepTimeInSeconds: 2, parentName: #function, backgrounder: nil, mySelfer: nil)
        ms.syncDelegate = syncDelegate
        ms.start(account: cdAccount.account())

        waitForExpectations(timeout: TestUtil.waitTimeForever) { error in
            XCTAssertNil(error)
        }
    }

    func testSyncWithErroneousAccount() {
        let expErrorOccurred = expectation(description: "expErrorOccurred")
        let errorDelegate = TestErrorDelegate(expErrorOccurred: expErrorOccurred)

        TestUtil.makeServersUnreachable(cdAccount: cdAccount)

        let ms = MessageSyncService(
            sleepTimeInSeconds: 2, parentName: #function, backgrounder: nil, mySelfer: nil)
        ms.errorDelegate = errorDelegate
        ms.start(account: cdAccount.account())

        waitForExpectations(timeout: TestUtil.waitTimeForever) { error in
            XCTAssertNil(error)
        }

        XCTAssertNotNil(errorDelegate.error)
    }

    func testTypicalNewAccountSetup() {
        let ms = MessageSyncService(
            sleepTimeInSeconds: 2, parentName: #function, backgrounder: nil, mySelfer: nil)

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
            numberOfOutgoingMessagesToSendLater: 0)
    }
}
