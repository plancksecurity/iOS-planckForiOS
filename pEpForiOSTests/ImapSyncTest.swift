//
//  ImapSyncTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

import pEpForiOS

class TestImapSyncDelegate: DefaultImapSyncDelegate {
    var errorOccurred = false
    var connectionTimeout = false
    var authSuccess = false
    var folderPrefetchSuccess = false
    var folderOpenSuccess = false
    var foldersFetched = false
    var messagePrefetched = false
    var folderStatusCompleted = false

    var errorExpectationFulfilled = false

    var message: CWIMAPMessage?
    var folderNames: [String] = []

    var errorOccurredExpectation: XCTestExpectation?
    var connectionTimeoutExpectation: XCTestExpectation?
    var authSuccessExpectation: XCTestExpectation?
    var folderPrefetchSuccessExpectation: XCTestExpectation?
    var folderOpenSuccessExpectation: XCTestExpectation?
    var foldersFetchedExpectation: XCTestExpectation?
    var folderStatusCompletedExpectation: XCTestExpectation?

    let fetchFolders: Bool
    let preFetchMails: Bool
    let openInbox: Bool

    init(fetchFolders: Bool = false, preFetchMails: Bool = false, openInbox: Bool = false) {
        self.fetchFolders = fetchFolders
        self.preFetchMails = preFetchMails
        self.openInbox = openInbox
        super.init()
    }

    func fulfillError(_ kind: String) {
        if let exp = errorOccurredExpectation {
            if !errorExpectationFulfilled {
                exp.fulfill()
                errorExpectationFulfilled = true
            } else {
                XCTAssertFalse(true, "This should not happen. Some cyclic dependency somewhere?")
            }
        }
    }

    override func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
        errorOccurred = true
        fulfillError("authenticationFailed")
    }

    override func connectionLost(_ sync: ImapSync, notification: Notification?) {
        errorOccurred = true
        fulfillError("connectionLost")
    }

    override func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
        errorOccurred = true
        fulfillError("connectionTerminated")
    }

    override func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
        errorOccurred = true
        connectionTimeout = true
        if let exp = connectionTimeoutExpectation {
            exp.fulfill()
        }
        fulfillError("connectionTimedOut")
    }

    func receivedFolderNames(_ sync: ImapSync, folderNames: [String]?) {
        if let folders = folderNames {
            self.folderNames = folders
            sync.openMailBox(ImapSync.defaultImapInboxName)
            foldersFetched = true
            if let exp = foldersFetchedExpectation {
                exp.fulfill()
            }
        }
    }

    override func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        if openInbox {
            sync.openMailBox(ImapSync.defaultImapInboxName)
        } else if fetchFolders {
            if let folderNames = sync.folderNames {
                receivedFolderNames(sync, folderNames: folderNames)
            }
        }
        authSuccess = true
        if let exp = authSuccessExpectation {
            exp.fulfill()
        }
    }

    override func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        folderPrefetchSuccess = true
        if let exp = folderPrefetchSuccessExpectation {
            exp.fulfill()
        }
    }

    override func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        errorOccurred = true
        fulfillError("folderOpenFailed")
    }

    override func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        folderOpenSuccess = true
        if let exp = folderOpenSuccessExpectation {
            exp.fulfill()
        }
        if preFetchMails {
            do {
                try sync.syncMessages()
            } catch  {
                folderPrefetchSuccess = false
                folderPrefetchSuccessExpectation?.fulfill()
            }
        }
    }

    override func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?)  {
        message = (notification as NSNotification?)?.userInfo?["Message"] as? CWIMAPMessage
        messagePrefetched = true
    }

    override func folderStatusCompleted(_ sync: ImapSync, notification: Notification?) {
        folderStatusCompleted = true
        if let exp = folderStatusCompletedExpectation {
            exp.fulfill()
        }
    }

    override func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        self.receivedFolderNames(sync, folderNames: sync.folderNames)
    }

    override func messageChanged(_ sync: ImapSync, notification: Notification?) {
    }
}

class ImapSyncTest: XCTestCase {
    var coreDataUtil: InMemoryCoreDataUtil!

    override func setUp() {
        super.setUp()
        coreDataUtil = InMemoryCoreDataUtil()
        TestUtil.adjustBaseLevel()
    }

    override func tearDown() {
        TestUtil.waitForServiceShutdown()
        super.tearDown()
    }

    /**
     Trying to connect to a host that surely doesn't exist should fail fast, but
     note there might be networks where this is not the case.
     */
    func testConnectionFailFast() {
        let del = TestImapSyncDelegate.init()
        let conInfo = ImapSmtpConnectInfo.init(
            nameOfTheUser: "The User",
            email: "", imapPassword: "", imapServerName: "doesnot.work",
            imapServerPort: 5000,
            imapTransport: .plain, smtpServerName: "", smtpServerPort: 5001, smtpTransport: .plain)
        let sync = ImapSync.init(connectInfo: conInfo)
        sync.delegate = del

        del.errorOccurredExpectation = expectation(description: "errorOccurred")

        sync.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertTrue(del.errorOccurred)
            XCTAssertTrue(del.connectionTimeout)
        })
        sync.close()
    }

    func testAuthSuccess() {
        let del = TestImapSyncDelegate.init()
        let conInfo = TestData.connectInfo
        let sync = ImapSync.init(connectInfo: conInfo)
        sync.delegate = del

        del.authSuccessExpectation = expectation(description: "authSuccess")

        sync.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertTrue(!del.errorOccurred)
            XCTAssertTrue(del.authSuccess)
        })
        sync.close()
    }

    func testFetchFolders() {
        let del = TestImapSyncDelegate.init(fetchFolders: true)
        let conInfo = TestData.connectInfo
        let sync = ImapSync.init(connectInfo: conInfo)
        sync.delegate = del

        del.foldersFetchedExpectation = expectation(description: "foldersFetched")

        sync.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertTrue(!del.errorOccurred)
            XCTAssertTrue(del.foldersFetched)
            XCTAssertTrue(del.folderNames.count > 0)
        })
        sync.close()
    }

    func prefetchMails(_ setup: PersistentSetup) -> ImapSync {
        let del = TestImapSyncDelegate.init(fetchFolders: true, preFetchMails: true,
                                            openInbox: false)
        let sync = ImapSync.init(connectInfo: setup.connectionInfo)
        sync.maxPrefetchCount = 10
        sync.delegate = del
        sync.folderBuilder = setup.folderBuilder

        del.folderPrefetchSuccessExpectation = expectation(description: "folderPrefetchSuccess")
        del.folderOpenSuccessExpectation = expectation(description: "folderOpenSuccess")

        sync.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertTrue(!del.errorOccurred)
            XCTAssertTrue(del.folderOpenSuccess)
            XCTAssertTrue(del.folderPrefetchSuccess)
        })

        if let folder = setup.model.folderByPredicate(
            setup.inboxFolderPredicate(), sortDescriptors: nil) {
            XCTAssertTrue(folder.messages.count > 0, "Expected messages in folder")
            XCTAssertLessThanOrEqual(folder.messages.count, Int(sync.maxPrefetchCount))
            for msg in folder.messages {
                if let m = msg as? CdMessage {
                    XCTAssertNotNil(m.subject)
                    XCTAssertNotNil(m.uid)
                } else {
                    XCTAssertTrue(false, "Expected object of type Message")
                }
            }
        } else {
            XCTAssertTrue(false, "Expected persisted folder")
        }
        return sync
    }

    func testPrefetchWithPersistence() {
        let setup = PersistentSetup.init()
        let _ = prefetchMails(setup)
        // Closing of connections should be automatic here, since the ImapSync created
        // in prefetchmails() went out of scope.
    }

    /**
     Test for directly opening a mailbox without fetching folders or prefetching any mails.
     */
    func testOpenMailboxWithoutPrefetch() {
        let setup = PersistentSetup.init()

        let del = TestImapSyncDelegate.init(fetchFolders: false, preFetchMails: false,
                                            openInbox: true)
        let sync = ImapSync.init(connectInfo: setup.connectionInfo)
        sync.delegate = del
        sync.folderBuilder = setup.folderBuilder

        del.folderOpenSuccessExpectation = expectation(description: "folderOpenSuccess")

        sync.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(del.errorOccurred)
            XCTAssertTrue(del.folderOpenSuccess)
            XCTAssertFalse(del.folderPrefetchSuccess)
        })

        setup.backgroundQueue.waitUntilAllOperationsAreFinished()

        let folder = setup.model.folderByPredicate(
            setup.inboxFolderPredicate(), sortDescriptors: nil)
        XCTAssertNotNil(folder, "Accessed folders should be created automatically")
        sync.close()
    }

    func testImapSupportedAuthMethodsBasic() {
        let sync = ImapSync.init(connectInfo: TestData.connectInfo)
        XCTAssertEqual(sync.bestAuthMethodFromList([]), AuthMethod.Login)
        XCTAssertEqual(sync.bestAuthMethodFromList(["CRAM-Md5", "pLAIn"]),
                       AuthMethod.CramMD5)
    }

    func testImapSupportedAuthMethods() {
        let del = TestImapSyncDelegate.init()
        let conInfo = TestData.connectInfo
        let sync = ImapSync.init(connectInfo: conInfo)
        sync.delegate = del

        del.authSuccessExpectation = expectation(description: "authSuccess")

        sync.start()

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertTrue(!del.errorOccurred)
            XCTAssertTrue(del.authSuccess)
            // Adapt this for different servers
            XCTAssertEqual(sync.bestAuthMethod(), AuthMethod.Login)
        })
    }
}
