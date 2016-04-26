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
    var connectionTimedOut = false
    var authSucess = false
    var foldersFetched = false
    var folderOpenSuccess = false
    var folderPrefetchSuccess = false
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
        if preFetchMails {
            sync.openMailBox(ImapSync.defaultImapInboxName)
        }
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

    func testPrefetchWithPersistence() {
        let del = TestImapSyncDelegate.init(fetchFolders: true, preFetchMails: true)
        let conInfo = TestData()
        let sync = ImapSync.init(coreDataUtil: coreDataUtil, connectInfo: conInfo)
        sync.delegate = del

        let account = Account.insertAccountFromConnectInfo(
            conInfo, context: coreDataUtil.managedObjectContext)
        XCTAssertNotNil(account)

        let backgroundQueue = NSOperationQueue.init()
        let connectionManager = ConnectionManager.init(coreDataUtil: coreDataUtil)
        let grandOperator = GrandOperator.init(connectionManager: connectionManager,
                                               coreDataUtil: coreDataUtil)
        let folderBuilder = ImapFolderBuilder.init(grandOperator: grandOperator,
                                                   connectInfo: conInfo,
                                                   backgroundQueue: backgroundQueue)
        sync.folderBuilder = folderBuilder

        sync.start()
        runloopFor(5, until: {
            return del.errorOccurred || (del.folderOpenSuccess && del.folderPrefetchSuccess)
        })
        XCTAssertTrue(!del.errorOccurred)
        XCTAssertTrue(del.folderOpenSuccess)
        XCTAssertTrue(del.folderPrefetchSuccess)

        backgroundQueue.waitUntilAllOperationsAreFinished()

        let p = NSPredicate.init(format: "account.email = %@ and name = %@", conInfo.email,
                                 ImapSync.defaultImapInboxName)
        if let folder = BaseManagedObject.singleEntityWithName(
            Folder.entityName(), predicate: p, context: coreDataUtil.managedObjectContext)
            as? Folder {
            XCTAssertTrue(folder.messages.count > 0, "Expected messages in folder")
        } else {
            XCTAssertTrue(false, "Expected persisted folder")
        }
    }
}
