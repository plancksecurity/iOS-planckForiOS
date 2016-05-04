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

struct PersistentSetup {
    let connectionInfo: ConnectInfo
    let connectionManager: ConnectionManager
    let backgroundQueue: NSOperationQueue
    let grandOperator: GrandOperator
    let folderBuilder: ImapFolderBuilder
    let model: IModel

    init(coreDataUtil: ICoreDataUtil) {
        connectionInfo = TestData.connectInfo
        backgroundQueue = NSOperationQueue.init()
        connectionManager = ConnectionManager.init()
        grandOperator = GrandOperator.init(
            connectionManager: connectionManager, coreDataUtil: coreDataUtil)
        folderBuilder = ImapFolderBuilder.init(grandOperator: grandOperator,
                                               connectInfo: connectionInfo,
                                               backgroundQueue: backgroundQueue)

        model = Model.init(context: coreDataUtil.managedObjectContext)
        let account = model.insertAccountFromConnectInfo(connectionInfo)
        XCTAssertNotNil(account)
    }

    func inboxFolderPredicate() -> NSPredicate {
        let p = NSPredicate.init(format: "account.email = %@ and name = %@",
                                 connectionInfo.email, ImapSync.defaultImapInboxName)
        return p
    }
}

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
    var messagePrefetchedExpectation: XCTestExpectation?
    var folderStatusCompletedExpectation: XCTestExpectation?

    let fetchFolders: Bool
    let preFetchMails: Bool
    let openInbox: Bool

    init(fetchFolders: Bool, preFetchMails: Bool, openInbox: Bool) {
        self.fetchFolders = fetchFolders
        self.preFetchMails = preFetchMails
        self.openInbox = openInbox
        super.init()
        print("init() \(unsafeAddressOf(self))")
    }

    convenience override init() {
        self.init(fetchFolders: false, preFetchMails: false, openInbox: false)
    }

    convenience init(fetchFolders: Bool) {
        self.init(fetchFolders: fetchFolders, preFetchMails: false, openInbox: false)
    }

    convenience init(openInbox: Bool, demandStatus: Bool) {
        self.init(fetchFolders: false, preFetchMails: false, openInbox: openInbox)
    }

    func fulfillError(kind: String) {
        if let exp = errorOccurredExpectation {
            if !errorExpectationFulfilled {
                exp.fulfill()
                errorExpectationFulfilled = true
            } else {
                XCTAssertFalse(true, "This should not happen. Some cyclic dependency somewhere?")
            }
        }
    }

    override func authenticationFailed(sync: ImapSync, notification: NSNotification?) {
        errorOccurred = true
        fulfillError("authenticationFailed")
    }

    override func connectionLost(sync: ImapSync, notification: NSNotification?) {
        errorOccurred = true
        fulfillError("connectionLost")
    }

    override func connectionTerminated(sync: ImapSync, notification: NSNotification?) {
        errorOccurred = true
        fulfillError("connectionTerminated")
    }

    override func connectionTimedOut(sync: ImapSync, notification: NSNotification?) {
        errorOccurred = true
        connectionTimeout = true
        if let exp = connectionTimeoutExpectation {
            exp.fulfill()
        }
        fulfillError("connectionTimedOut")
    }

    func receivedFolderNames(sync: ImapSync, folderNames: [String]?) {
        if let folders = folderNames {
            self.folderNames = folders
            sync.openMailBox(ImapSync.defaultImapInboxName, prefetchMails: preFetchMails)
            foldersFetched = true
            if let exp = foldersFetchedExpectation {
                exp.fulfill()
            }
        }
    }

    override func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        if openInbox {
            sync.openMailBox(ImapSync.defaultImapInboxName, prefetchMails: false)
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

    override func folderPrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        folderPrefetchSuccess = true
        if let exp = folderPrefetchSuccessExpectation {
            exp.fulfill()
        }
    }

    override func folderOpenFailed(sync: ImapSync, notification: NSNotification?) {
        errorOccurred = true
        fulfillError("folderOpenFailed")
    }

    override func folderOpenCompleted(sync: ImapSync, notification: NSNotification?) {
        folderOpenSuccess = true
        if let exp = folderOpenSuccessExpectation {
            exp.fulfill()
        }
    }

    override func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?)  {
        message = notification?.userInfo?["Message"] as? CWIMAPMessage
        messagePrefetched = true
        if let exp = messagePrefetchedExpectation {
            exp.fulfill()
        }
    }

    override func folderStatusCompleted(sync: ImapSync, notification: NSNotification?) {
        folderStatusCompleted = true
        if let exp = folderStatusCompletedExpectation {
            exp.fulfill()
        }
    }

    override func folderListCompleted(sync: ImapSync, notification: NSNotification?) {
        self.receivedFolderNames(sync, folderNames: sync.folderNames)
    }
}

class ImapSyncTest: XCTestCase {
    let waitTime: NSTimeInterval = 10

    var coreDataUtil: InMemoryCoreDataUtil!

    override func setUp() {
        super.setUp()
        coreDataUtil = InMemoryCoreDataUtil()
    }

    func testConnectionFail() {
        let del = TestImapSyncDelegate.init()
        let conInfo = ConnectInfo.init(
            email: "", imapPassword: "", imapServerName: "doesnot.work",
            imapServerPort: 5000,
            imapTransport: .Plain, smtpServerName: "", smtpServerPort: 5001, smtpTransport: .Plain)
        let sync = ImapSync.init(connectInfo: conInfo)
        sync.delegate = del

        del.errorOccurredExpectation = expectationWithDescription("errorOccurred")

        sync.start()

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertTrue(del.errorOccurred)
            XCTAssertTrue(del.connectionTimeout)
        })
    }

    func testAuthSuccess() {
        let del = TestImapSyncDelegate.init()
        let conInfo = TestData.connectInfo
        let sync = ImapSync.init(connectInfo: conInfo)
        sync.delegate = del

        del.authSuccessExpectation = expectationWithDescription("authSuccess")

        sync.start()

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertTrue(!del.errorOccurred)
            XCTAssertTrue(del.authSuccess)
        })
    }

    func testFetchFolders() {
        let del = TestImapSyncDelegate.init(fetchFolders: true)
        let conInfo = TestData.connectInfo
        let sync = ImapSync.init(connectInfo: conInfo)
        sync.delegate = del

        del.foldersFetchedExpectation = expectationWithDescription("foldersFetched")

        sync.start()

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertTrue(!del.errorOccurred)
            XCTAssertTrue(del.foldersFetched)
            XCTAssertTrue(del.folderNames.count > 0)
        })
    }

    func prefetchMails(setup: PersistentSetup) -> ImapSync {
        let del = TestImapSyncDelegate.init(fetchFolders: true, preFetchMails: true,
                                            openInbox: false)
        let sync = ImapSync.init(connectInfo: setup.connectionInfo)
        sync.delegate = del
        sync.folderBuilder = setup.folderBuilder

        del.folderPrefetchSuccessExpectation = expectationWithDescription("folderPrefetchSuccess")
        del.folderOpenSuccessExpectation = expectationWithDescription("folderOpenSuccess")

        sync.start()

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertTrue(!del.errorOccurred)
            XCTAssertTrue(del.folderOpenSuccess)
            XCTAssertTrue(del.folderPrefetchSuccess)
        })

        setup.backgroundQueue.waitUntilAllOperationsAreFinished()

        if let folder = setup.model.folderByPredicate(setup.inboxFolderPredicate())
            as? Folder {
            XCTAssertTrue(folder.messages.count > 0, "Expected messages in folder")
        } else {
            XCTAssertTrue(false, "Expected persisted folder")
        }
        return sync
    }

    func testPrefetchWithPersistence() {
        let setup = PersistentSetup.init(coreDataUtil: coreDataUtil)
        prefetchMails(setup)
    }

    /**
     Test for directly opening a mailbox without fetching folders or prefetching any mails.
     */
    func testOpenMailboxWithoutPrefetch() {
        let setup = PersistentSetup.init(coreDataUtil: coreDataUtil)

        let del = TestImapSyncDelegate.init(fetchFolders: false, preFetchMails: false,
                                            openInbox: true)
        let sync = ImapSync.init(connectInfo: setup.connectionInfo)
        sync.delegate = del
        sync.folderBuilder = setup.folderBuilder

        del.folderOpenSuccessExpectation = expectationWithDescription("folderOpenSuccess")

        sync.start()

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertTrue(!del.errorOccurred)
            XCTAssertTrue(del.folderOpenSuccess)
            XCTAssertFalse(del.folderPrefetchSuccess)
        })

        setup.backgroundQueue.waitUntilAllOperationsAreFinished()

        let folder = setup.model.folderByPredicate(setup.inboxFolderPredicate())
            as? Folder
        XCTAssertNil(folder, "Unexpected persisted folder")
    }

    func testFetchMail() {
        let setup = PersistentSetup.init(coreDataUtil: coreDataUtil)
        let sync = prefetchMails(setup)
        if let folder = setup.model.folderByPredicate(setup.inboxFolderPredicate())
            as? Folder {
            XCTAssertTrue(folder.messages.count > 0, "Expected messages in folder")
            let message = folder.messages.anyObject() as! Message
            XCTAssertNotNil(message)
            XCTAssertNotNil(message.uid)
            XCTAssertTrue(message.uid?.intValue > 0)
            XCTAssertNil(message.content)

            let del = TestImapSyncDelegate.init(fetchFolders: false, preFetchMails: false,
                                                openInbox: false)
            sync.delegate = del

            del.messagePrefetchedExpectation = expectationWithDescription("messagePrefetched")

            sync.fetchMailFromFolderNamed(ImapSync.defaultImapInboxName,
                                          uid: message.uid!.integerValue)
            waitForExpectationsWithTimeout(waitTime, handler: { error in
                XCTAssertNil(error)
                XCTAssertTrue(!del.errorOccurred)
                XCTAssertTrue(del.messagePrefetched)
                XCTAssertNotNil(del.message)
                XCTAssertTrue(del.message!.isInitialized())
                XCTAssertEqual(del.message!.UID(), UInt(message.uid!.integerValue))
                XCTAssertNotNil(del.message!.content())
                let data = del.message!.content() as? NSData
                XCTAssertNotNil(data)
                let s = String.init(data: data!, encoding: NSUTF8StringEncoding)
                XCTAssertNotNil(s)
            })
        } else {
            XCTAssertTrue(false, "Expected persisted folder")
        }
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

        del.authSuccessExpectation = expectationWithDescription("authSuccess")

        sync.start()

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertTrue(!del.errorOccurred)
            XCTAssertTrue(del.authSuccess)
            // Adapt this for different servers
            XCTAssertEqual(sync.bestAuthMethod(), AuthMethod.Login)
        })
    }
}
