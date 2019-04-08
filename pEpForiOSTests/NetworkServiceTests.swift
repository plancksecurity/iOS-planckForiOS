//
//  NetworkServiceTests.swift
//  pEpForiOS
//
//  Created by hernani on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import MessageModel
@testable import pEpForiOS

class NetworkServiceTests: XCTestCase {
    var persistenceSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistenceSetup = PersistentSetup()
    }

    override func tearDown() {
        persistenceSetup = nil
        super.tearDown()
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

        let networkService = NetworkService(parentName: #function)

        let del = NetworkServiceObserver(
            expAccountsSynced: expectation(description: "expSingleAccountSynced"))
        networkService.unitTestDelegate = del
        networkService.delegate = del

        _ = SecretTestData().createWorkingCdAccount()
        Record.saveAndWait()

        networkService.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        TestUtil.cancelNetworkServiceAndWait(networkService: networkService, testCase: self)

        XCTAssertNotNil(del.accountInfo)
        XCTAssertNotNil(CdFolder.all())


    }

    func testCancelSyncImmediately() {
        XCTAssertNil(CdAccount.all())
        XCTAssertNil(CdFolder.all())
        XCTAssertNil(CdMessage.all())

        let networkService = NetworkService(parentName: #function)

        _ = SecretTestData().createWorkingCdAccount()
        Record.saveAndWait()

        for _ in 0...10 {
            networkService.start()
            TestUtil.cancelNetworkServiceAndWait(networkService: networkService, testCase: self)
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

        let cdAccount = useCorrectSmtpAccount ? SecretTestData().createWorkingCdAccount() :
            SecretTestData().createSmtpTimeOutCdAccount()
        Record.saveAndWait()

        TestUtil.syncAndWait(testCase: self)

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
        let outgoingMails = try! TestUtil.createOutgoingMails(
            cdAccount: cdAccount,
            testCase: self, numberOfMails: numMails)
        let outgoingMessageIDs: [String] = outgoingMails
            .map() { $0.messageID ?? "" }
            .filter() { $0 != "" }

        // Verify outgoing mails
        for m in outgoingMails {
            XCTAssertEqual(m.parent?.folderType, FolderType.outbox)
            XCTAssertEqual(m.uid, Int32(0))
        }

        TestUtil.syncAndWait(testCase: self)

        // Check that the sent mails have been deleted
        Record.refreshRegisteredObjects(mergeChanges: true)
        if useCorrectSmtpAccount {
            for m in outgoingMails {
                XCTAssertTrue(m.isDeleted)
            }
        }

        // sync
        TestUtil.syncAndWait(testCase: self)

        if useCorrectSmtpAccount {
            // those messages do not exist if we are using an incorrect account
            TestUtil.checkForExistanceAndUniqueness(uuids: outgoingMessageIDs)
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

        func didUpdate(message: Message) {
            // messages has been changed during the test
            XCTAssertNotNil(messagesByID[message.messageID])
            add(message: message)
            changedMessagesByID[message.messageID] = message
        }

        func didDelete(message: Message) {
            // this message has been deleted from the start, ignore
        }

        func didCreate(message: Message) {
            add(message: message)
        }
    }
}
