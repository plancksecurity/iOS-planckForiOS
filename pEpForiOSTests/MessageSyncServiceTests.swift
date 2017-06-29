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
                XCTFail()
            }
        }
    }

    class TestSentDelegate: MessageSyncServiceSentDelegate {
        let expAllSent: XCTestExpectation
        let expectedMessageCount: Int

        var sentMessageIDs = Set<String>()
        var currentMessageCount = 0

        init(expAllSent: XCTestExpectation, expectedMessageCount: Int) {
            self.expAllSent = expAllSent
            self.expectedMessageCount = expectedMessageCount
        }

        func didSend(message: Message) {
            if sentMessageIDs.contains(message.messageID) {
                XCTFail("message sent double")
            } else {
                sentMessageIDs.insert(message.messageID)
                currentMessageCount += 1
                if currentMessageCount == expectedMessageCount {
                    expAllSent.fulfill()
                }
            }
        }
    }

    override func setUp() {
        super.setUp()
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

    func runMessageSyncServiceSend(cdAccount theCdAccount: CdAccount, numberOfMessagesToSend: Int) {
        let outgoingCdMsgs = TestUtil.createOutgoingMails(cdAccount: theCdAccount)

        let expBackgrounded = expectation(description: "expBackgrounded")
        let mbg = MockBackgrounder(expBackgrounded: expBackgrounded)
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
        let sentDelegate = TestSentDelegate(expAllSent: expAllSent,
                                            expectedMessageCount: numberOfMessagesToSend)
        ms.sentDelegate = sentDelegate

        for msg in msgsToSend {
            ms.requestSend(message: msg)
        }

        waitForExpectations(timeout: TestUtil.waitTimeForever) { error in
            XCTAssertNil(error)
        }

        XCTAssertNil(errorDelegate.error)
        XCTAssertEqual(sentDelegate.currentMessageCount, numberOfMessagesToSend)
        XCTAssertEqual(sentDelegate.sentMessageIDs.count, numberOfMessagesToSend)

        for msg in msgsToSend {
            XCTAssertTrue(sentDelegate.sentMessageIDs.contains(msg.messageID))
        }
    }

    func testBasicSend() {
        runMessageSyncServiceSend(cdAccount: cdAccount, numberOfMessagesToSend: 1)
    }
}
