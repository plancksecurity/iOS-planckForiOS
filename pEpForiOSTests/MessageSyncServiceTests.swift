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
        let outgoingCdMsgs = TestUtil.createOutgoingMails(
            cdAccount: theCdAccount, testCase: self,
            numberOfMails: numberOfOutgoingMessagesToCreate)

        if outgoingCdMsgs.count < numberOfOutgoingMessagesToCreate {
            XCTFail()
            return
        }

        let expBackgroundTaskFinished = expectation(description: "expBackgrounded")
        expBackgroundTaskFinished.expectedFulfillmentCount =
            UInt(expectedNumberOfExpectedBackgroundTasks)
        let mbg = MockBackgrounder(expBackgroundTaskFinishedAtLeastOnce: expBackgroundTaskFinished)
        let ms = MessageSyncService(
            sleepTimeInSeconds: 2, parentName: #function, backgrounder: mbg, mySelfer: nil)

        let cdMsgsToSend = outgoingCdMsgs.prefix(numberOfOutgoingMessagesToSend)
        XCTAssertEqual(cdMsgsToSend.count, numberOfOutgoingMessagesToSend)
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

        let expMessagesSent = expectation(description: "expMessagesSent")
        let sentDelegate = TestSentDelegate(expMessagesSent: expMessagesSent)
        ms.sentDelegate = sentDelegate

        ms.start(account: cdAccount.account())
        for i in 0..<numberOfOutgoingMessagesToSend {
            ms.requestSend(message: msgsToSend[i])
        }

        waitForExpectations(timeout: TestUtil.waitTimeForever) { error in
            XCTAssertNil(error)
        }

        XCTAssertNil(errorDelegate.error)
        XCTAssertEqual(sentDelegate.requestedMessagesSent.count, numberOfOutgoingMessagesToSend)
        XCTAssertEqual(sentDelegate.messageIDsSent.count, numberOfOutgoingMessagesToCreate)

        for msg in msgsToSend {
            XCTAssertTrue(sentDelegate.messageIDsSent.contains(msg.messageID))
        }

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
            numberOfOutgoingMessagesToSend: 0,
            expectedNumberOfExpectedBackgroundTasks: 4)
    }

    func testSendSeveral() {
        runMessageSyncServiceSend(
            cdAccount: cdAccount,
            numberOfOutgoingMessagesToCreate: 3,
            numberOfOutgoingMessagesToSend: 2,
            expectedNumberOfExpectedBackgroundTasks: 5)
    }
}
