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
    let connectionmanager: ConnectionManager
    let backgroundQueue: NSOperationQueue
    let grandOperator: GrandOperator
    let folderBuilder: ImapFolderBuilder

    func inboxFolderPredicate() -> NSPredicate {
        let p = NSPredicate.init(format: "account.email = %@ and name = %@",
                                 connectionInfo.email, ImapSync.defaultImapInboxName)
        return p
    }
}

class TestImapSyncDelegate: DefaultImapSyncDelegate {
    var errorOccurred = false
    var connectionTimedOut = false
    var authSucess = false
    var foldersFetched = false
    var folderOpenSuccess = false
    var folderPrefetchSuccess = false
    var messagePrefetched = false
    var message: CWIMAPMessage?
    var folderNames: [String] = []

    let fetchFolders: Bool
    let preFetchMails: Bool

    init(fetchFolders: Bool, preFetchMails: Bool) {
        self.fetchFolders = fetchFolders
        self.preFetchMails = preFetchMails
    }

    convenience override init() {
        self.init(fetchFolders: false, preFetchMails: false)
    }

    convenience init(fetchFolders: Bool) {
        self.init(fetchFolders: fetchFolders, preFetchMails: false)
    }

    override func authenticationFailed(sync: ImapSync, notification: NSNotification?) {
        errorOccurred = true
    }

    override func connectionLost(sync: ImapSync, notification: NSNotification?) {
        errorOccurred = true
    }

    override func connectionTerminated(sync: ImapSync, notification: NSNotification?) {
        errorOccurred = true
    }

    override func connectionTimedOut(sync: ImapSync, notification: NSNotification?) {
        connectionTimedOut = true
        errorOccurred = true
    }

    override func receivedFolderNames(sync: ImapSync, folderNames: [String]) {
        foldersFetched = true
        self.folderNames = folderNames
        sync.openMailBox(ImapSync.defaultImapInboxName, prefetchMails: preFetchMails)
    }

    override func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        authSucess = true
        if  fetchFolders || preFetchMails {
            sync.waitForFolders()
        }
    }

    override func folderPrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        folderPrefetchSuccess = true
    }

    override func folderOpenFailed(sync: ImapSync, notification: NSNotification?) {
        errorOccurred = true
    }

    override func folderOpenCompleted(sync: ImapSync, notification: NSNotification?) {
        folderOpenSuccess = true
    }

    override func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?)  {
        messagePrefetched = true
        message = notification?.userInfo?["Message"] as? CWIMAPMessage
    }
}

class ImapSyncTest: XCTestCase {
    var coreDataUtil: InMemoryCoreDataUtil!

    override func setUp() {
        super.setUp()
        coreDataUtil = InMemoryCoreDataUtil()
    }

    /**
     Runs the runloop until either some time has elapsed or a predicate is true.
     */
    func runloopFor(time: CFAbsoluteTime, until: () -> Bool) {
        let now = CFAbsoluteTimeGetCurrent()
        while CFAbsoluteTimeGetCurrent() - now < time && !until() {
            NSRunLoop.mainRunLoop().runMode(
                NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
        }
    }

    func testConnectionFail() {
        let del = TestImapSyncDelegate.init()
        let conInfo = ConnectInfo.init(
            email: "", imapPassword: "", imapAuthMethod: "",
            smtpAuthMethod: "", imapServerName: "doesnot.work", imapServerPort: 5000,
            imapTransport: .Plain, smtpServerName: "", smtpServerPort: 5001, smtpTransport: .Plain)
        let sync = ImapSync.init(coreDataUtil: coreDataUtil, connectInfo: conInfo)
        sync.delegate = del
        sync.start()
        runloopFor(2, until: { return del.errorOccurred })
        XCTAssertTrue(del.errorOccurred)
        XCTAssertTrue(del.connectionTimedOut)
    }

    func testAuthSuccess() {
        let del = TestImapSyncDelegate.init()
        let conInfo = TestData()
        let sync = ImapSync.init(coreDataUtil: coreDataUtil, connectInfo: conInfo)
        sync.delegate = del
        sync.start()
        runloopFor(5, until: {
            return del.errorOccurred || del.authSucess
        })
        XCTAssertTrue(!del.errorOccurred)
        XCTAssertTrue(del.authSucess)
    }

    func testFetchFolders() {
        let del = TestImapSyncDelegate.init(fetchFolders: true)
        let conInfo = TestData()
        let sync = ImapSync.init(coreDataUtil: coreDataUtil, connectInfo: conInfo)
        sync.delegate = del
        sync.start()
        runloopFor(5, until: {
            return del.errorOccurred || del.foldersFetched
        })
        XCTAssertTrue(!del.errorOccurred)
        XCTAssertTrue(del.foldersFetched)
        XCTAssertTrue(del.folderNames.count > 0)
    }

    func setupMemoryPersistence() -> PersistentSetup {
        let conInfo = TestData()
        let backgroundQueue = NSOperationQueue.init()
        let connectionManager = ConnectionManager.init(coreDataUtil: coreDataUtil)
        let grandOperator = GrandOperator.init(connectionManager: connectionManager,
                                               coreDataUtil: coreDataUtil)
        let folderBuilder = ImapFolderBuilder.init(grandOperator: grandOperator,
                                                   connectInfo: conInfo,
                                                   backgroundQueue: backgroundQueue)

        let account = Account.insertAccountFromConnectInfo(
            conInfo, context: coreDataUtil.managedObjectContext)
        XCTAssertNotNil(account)

        return PersistentSetup.init(
            connectionInfo: conInfo, connectionmanager: connectionManager,
            backgroundQueue: backgroundQueue, grandOperator: grandOperator,
            folderBuilder: folderBuilder)
    }

    func prefetchMails(setup: PersistentSetup) -> ImapSync {
        let del = TestImapSyncDelegate.init(fetchFolders: true, preFetchMails: true)
        let sync = ImapSync.init(coreDataUtil: coreDataUtil, connectInfo: setup.connectionInfo)
        sync.delegate = del
        sync.folderBuilder = setup.folderBuilder

        sync.start()
        runloopFor(5, until: {
            return del.errorOccurred || (del.folderOpenSuccess && del.folderPrefetchSuccess)
        })
        XCTAssertTrue(!del.errorOccurred)
        XCTAssertTrue(del.folderOpenSuccess)
        XCTAssertTrue(del.folderPrefetchSuccess)

        setup.backgroundQueue.waitUntilAllOperationsAreFinished()

        if let folder = BaseManagedObject.singleEntityWithName(
            Folder.entityName(), predicate: setup.inboxFolderPredicate(),
            context: coreDataUtil.managedObjectContext)
            as? Folder {
            XCTAssertTrue(folder.messages.count > 0, "Expected messages in folder")
        } else {
            XCTAssertTrue(false, "Expected persisted folder")
        }
        return sync
    }

    func testPrefetchWithPersistence() {
        let setup = setupMemoryPersistence()
        prefetchMails(setup)
    }

    func testOpenMailboxWithoutPrefetch() {
        let setup = setupMemoryPersistence()

        let del = TestImapSyncDelegate.init(fetchFolders: true, preFetchMails: false)
        let sync = ImapSync.init(coreDataUtil: coreDataUtil, connectInfo: setup.connectionInfo)
        sync.delegate = del
        sync.folderBuilder = setup.folderBuilder

        sync.start()
        runloopFor(5, until: {
            return del.errorOccurred || (del.folderOpenSuccess)
        })
        XCTAssertTrue(!del.errorOccurred)
        XCTAssertTrue(del.folderOpenSuccess)
        XCTAssertFalse(del.folderPrefetchSuccess)

        setup.backgroundQueue.waitUntilAllOperationsAreFinished()

        let folder = BaseManagedObject.singleEntityWithName(
            Folder.entityName(), predicate: setup.inboxFolderPredicate(),
            context: coreDataUtil.managedObjectContext)
            as? Folder
        XCTAssertNil(folder, "Unexpected persisted folder")
    }

    func testFetchMail() {
        let setup = setupMemoryPersistence()
        let sync = prefetchMails(setup)
        if let folder = BaseManagedObject.singleEntityWithName(
            Folder.entityName(), predicate: setup.inboxFolderPredicate(),
            context: coreDataUtil.managedObjectContext)
            as? Folder {
            XCTAssertTrue(folder.messages.count > 0, "Expected messages in folder")
            let message = folder.messages.anyObject() as! Message
            XCTAssertNotNil(message)
            XCTAssertNotNil(message.uid)
            XCTAssertTrue(message.uid?.intValue > 0)
            XCTAssertNil(message.content)

            let del = TestImapSyncDelegate.init(fetchFolders: true, preFetchMails: false)
            sync.delegate = del
            sync.fetchMailFromFolderNamed(ImapSync.defaultImapInboxName,
                                          uid: message.uid!.integerValue)
            runloopFor(5, until: {
                return del.messagePrefetched
            })
            XCTAssertTrue(del.messagePrefetched)
            XCTAssertNotNil(del.message)
            XCTAssertTrue(del.message!.isInitialized())
            XCTAssertEqual(del.message!.UID(), UInt(message.uid!.integerValue))
            XCTAssertNotNil(del.message!.content())
            let data = del.message!.content() as? NSData
            XCTAssertNotNil(data)
            let s = String.init(data: data!, encoding: NSUTF8StringEncoding)
            XCTAssertNotNil(s)
        } else {
            XCTAssertTrue(false, "Expected persisted folder")
        }
    }
}
