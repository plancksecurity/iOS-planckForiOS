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
                                   numberOfOutgoingMessagesToCreate: Int,
                                   numberOfOutgoingMessagesToSend: Int,
                                   expectedNumberOfExpectedBackgroundTasks: Int) {
        let outgoingCdMsgs = TestUtil.createOutgoingMails(cdAccount: theCdAccount, testCase: self)

        let expBackgroundTaskFinished = expectation(description: "expBackgrounded")
        expBackgroundTaskFinished.expectedFulfillmentCount =
            UInt(expectedNumberOfExpectedBackgroundTasks)
        let mbg = MockBackgrounder(expBackgroundTaskFinishedAtLeastOnce: expBackgroundTaskFinished)
        let ms = MessageSyncService(
            sleepTimeInSeconds: 2, parentName: #function, backgrounder: mbg, mySelfer: nil)

        if outgoingCdMsgs.count < numberOfOutgoingMessagesToCreate {
            XCTFail()
            return
        }

        let cdMsgsToSend = outgoingCdMsgs.dropLast(outgoingCdMsgs.count - numberOfOutgoingMessagesToCreate)
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
        expAllSent.expectedFulfillmentCount = UInt(numberOfOutgoingMessagesToCreate)
        let sentDelegate = TestSentDelegate(expAllSent: expAllSent)
        ms.sentDelegate = sentDelegate

        ms.start(account: cdAccount.account())
        for i in 0..<numberOfOutgoingMessagesToSend {
            ms.requestSend(message: msgsToSend[i])
        }

        waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }

        XCTAssertNil(errorDelegate.error)
        XCTAssertEqual(sentDelegate.currentMessageCount, numberOfOutgoingMessagesToCreate)
        XCTAssertEqual(sentDelegate.sentMessageIDs.count, numberOfOutgoingMessagesToCreate)

        for msg in msgsToSend {
            XCTAssertTrue(sentDelegate.sentMessageIDs.contains(msg.messageID))
        }

        XCTAssertEqual(mbg.numberOfBackgroundTasksOutstanding, 0)
        XCTAssertEqual(mbg.totalNumberOfBackgroundTasksFinished, expectedNumberOfExpectedBackgroundTasks)
        XCTAssertEqual(mbg.totalNumberOfBackgroundTasksStarted,
                       mbg.totalNumberOfBackgroundTasksFinished)
    }

    func testBasicSend() {
        runMessageSyncServiceSend(
            cdAccount: cdAccount,
            numberOfOutgoingMessagesToCreate: 1,
            numberOfOutgoingMessagesToSend: 1,
            expectedNumberOfExpectedBackgroundTasks: 5)
    }

    func testSendSeveral() {
        runMessageSyncServiceSend(
            cdAccount: cdAccount,
            numberOfOutgoingMessagesToCreate: 2,
            numberOfOutgoingMessagesToSend: 2,
            expectedNumberOfExpectedBackgroundTasks: 5)
    }

    /*
    func testSendWithoutRequest() {
        runMessageSyncServiceSend(
            cdAccount: cdAccount,
            numberOfOutgoingMessagesToCreate: 2,
            numberOfOutgoingMessagesToSend: 1,
            expectedNumberOfExpectedBackgroundTasks: 5)
    }
     */
}
