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
        let expAllSent: XCTestExpectation

        var sentMessageIDs = Set<String>()
        var currentMessageCount = 0

        init(expAllSent: XCTestExpectation) {
            self.expAllSent = expAllSent
        }

        func didSend(message: Message) {
            if sentMessageIDs.contains(message.messageID) {
                XCTFail("message sent double")
            } else {
                sentMessageIDs.insert(message.messageID)
                currentMessageCount += 1
                expAllSent.fulfill()
            }
        }
    }

    override func setUp() {
        super.setUp()

        continueAfterFailure = false

        persistentSetup = PersistentSetup()

        let cdAccount = TestData().createWorkingCdAccount()
        cdAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount

        let cdDisfunctionalAccount = TestData().createDisfunctionalCdAccount()
        cdDisfunctionalAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccountDisfunctional = cdDisfunctionalAccount
    }

    func runMessageSyncServiceSend(cdAccount theCdAccount: CdAccount,
                                   numberOfMessagesToSend: Int,
                                   expectedNumberOfExpectedBackgroundTasks: Int,
                                   requestMessageSend: Bool) {
        let outgoingCdMsgs = TestUtil.createOutgoingMails(cdAccount: theCdAccount, testCase: self)

        let expBackgroundTaskFinished = expectation(description: "expBackgrounded")
        expBackgroundTaskFinished.expectedFulfillmentCount =
            UInt(expectedNumberOfExpectedBackgroundTasks)
        let mbg = MockBackgrounder(expBackgroundTaskFinishedAtLeastOnce: expBackgroundTaskFinished)
        let ms = MessageSyncService(
            sleepTimeInSeconds: 2, parentName: #function, backgrounder: mbg, mySelfer: nil)

        if outgoingCdMsgs.count < numberOfMessagesToSend {
            XCTFail()
            return
        }

        let cdMsgsToSend = outgoingCdMsgs.dropLast(outgoingCdMsgs.count - numberOfMessagesToSend)
        var msgsToSend = [Message]()
        for cdMsg in cdMsgsToSend {
            guard let msg = cdMsg.message() else {
                XCTFail()
                return
            }
            msgsToSend.append(msg)
        }

        let errorDelegate = TestErrorDelegate()
        ms.errorDelegate = errorDelegate

        let expAllSent = expectation(description: "expAllSent")
        expAllSent.expectedFulfillmentCount = UInt(numberOfMessagesToSend)
        let sentDelegate = TestSentDelegate(expAllSent: expAllSent)
        ms.sentDelegate = sentDelegate

        for msg in msgsToSend {
            ms.requestSend(message: msg)
        }

        waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }

        XCTAssertNil(errorDelegate.error)
        XCTAssertEqual(sentDelegate.currentMessageCount, numberOfMessagesToSend)
        XCTAssertEqual(sentDelegate.sentMessageIDs.count, numberOfMessagesToSend)

        for msg in msgsToSend {
            XCTAssertTrue(sentDelegate.sentMessageIDs.contains(msg.messageID))
        }

        XCTAssertEqual(mbg.numberOfBackgroundTasksOutstanding, 0)
        XCTAssertEqual(mbg.totalNumberOfBackgroundTasksFinished, expectedNumberOfExpectedBackgroundTasks)
        XCTAssertEqual(mbg.totalNumberOfBackgroundTasksStarted,
                       mbg.totalNumberOfBackgroundTasksFinished)
    }

    func testBasicSend() {
        let expectedNumberOfExpectedBackgroundTasks = 2 // 1 fetching folders, 1 sending
        runMessageSyncServiceSend(
            cdAccount: cdAccount,
            numberOfMessagesToSend: 1,
            expectedNumberOfExpectedBackgroundTasks: expectedNumberOfExpectedBackgroundTasks,
            requestMessageSend: true)
    }

    func testSendSeveral() {
        let expectedNumberOfExpectedBackgroundTasks = 2 // 1 fetching folders, 1 sending
        runMessageSyncServiceSend(
            cdAccount: cdAccount,
            numberOfMessagesToSend: 2,
            expectedNumberOfExpectedBackgroundTasks: expectedNumberOfExpectedBackgroundTasks,
            requestMessageSend: true)
    }

    func testSendWithoutRequest() {
        let expectedNumberOfExpectedBackgroundTasks = 2 // 1 fetching folders, 1 sending
        runMessageSyncServiceSend(
            cdAccount: cdAccount,
            numberOfMessagesToSend: 2,
            expectedNumberOfExpectedBackgroundTasks: expectedNumberOfExpectedBackgroundTasks,
            requestMessageSend: false)
    }
}
