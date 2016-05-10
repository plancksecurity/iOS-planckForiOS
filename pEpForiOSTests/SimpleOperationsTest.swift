//
//  SimpleOperationsTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

import pEpForiOS

class SimpleOperationsTest: XCTestCase {
    let waitTime: NSTimeInterval = 10

    let coreDataUtil = InMemoryCoreDataUtil.init()
    var persistentSetup: PersistentSetup!
    var grandOperator: IGrandOperator!
    var connectInfo: ConnectInfo!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup.init(coreDataUtil: coreDataUtil)
        grandOperator = GrandOperator.init(connectionManager: ConnectionManager.init(),
                                           coreDataUtil: coreDataUtil)
        connectInfo = TestData.connectInfo
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testPrefetchMailsOperation() {
        let mailsPrefetched = expectationWithDescription("mailsPrefetched")

        let op = PrefetchEmailsOperation.init(grandOperator: grandOperator,
                                              connectInfo: connectInfo,
                                              folder: ImapSync.defaultImapInboxName)
        op.completionBlock = {
            mailsPrefetched.fulfill()
        }

        op.start()
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertGreaterThan(
                self.grandOperator.model.folderCountByPredicate(NSPredicate.init(value: true)), 0)
            XCTAssertGreaterThan(
                self.grandOperator.model.messageCountByPredicate(NSPredicate.init(value: true)), 0)
        })
    }

    func testFetchFoldersOperation() {
        let foldersFetched = expectationWithDescription("foldersFetched")

        let op = FetchFoldersOperation.init(grandOperator: grandOperator,
                                            connectInfo: connectInfo)
        op.completionBlock = {
            foldersFetched.fulfill()
        }

        op.start()
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertGreaterThan(
                self.grandOperator.model.folderCountByPredicate(NSPredicate.init(value: true)), 1)
            XCTAssertEqual(self.grandOperator.model.folderByName(
                ImapSync.defaultImapInboxName, email: self.connectInfo.email)?.name.lowercaseString,
                ImapSync.defaultImapInboxName.lowercaseString)
        })
    }

    func testStoreSingleMail() {
        grandOperator.model.insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderType: Account.AccountType.Imap,
            accountEmail: connectInfo.email)
        grandOperator.model.save()

        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)
        let message = CWIMAPMessage.init()
        message.setFrom(CWInternetAddress.init(personal: "personal", address: "somemail@test.com"))
        message.setFolder(folder)
        let op = StorePrefetchedMailOperation.init(grandOperator: self.grandOperator,
                                                   accountEmail: connectInfo.email,
                                                   message: message, inBackground: true)
        let backgroundQueue = NSOperationQueue.init()
        backgroundQueue.addOperation(op)
        backgroundQueue.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(
            self.grandOperator.model.messageCountByPredicate(NSPredicate.init(value: true)), 1)
    }

    func testStoreMultipleMails() {
        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)
        let numMails = 10

        grandOperator.model.insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderType: Account.AccountType.Imap,
            accountEmail: connectInfo.email)
        grandOperator.model.save()

        let exp = expectationWithDescription("exp")
        var operations: Set<NSOperation> = []
        let backgroundQueue = NSOperationQueue.init()
        var fulfilled = false
        for i in 1...numMails {
            let message = CWIMAPMessage.init()
            message.setFrom(CWInternetAddress.init(personal: "personal\(i)",
                address: "somemail\(i)@test.com"))
            message.setSubject("Subject \(i)")
            message.setRecipients([CWInternetAddress.init(personal: "thisIsMe",
                address: "myaddress@test.com", type: PantomimeToRecipient)])
            message.setFolder(folder)
            message.setUID(UInt(i))
            let op = StorePrefetchedMailOperation.init(grandOperator: self.grandOperator,
                                                       accountEmail: connectInfo.email,
                                                       message: message, inBackground: true)
            operations.insert(op)
            op.completionBlock = {
                operations.remove(op)
                if backgroundQueue.operationCount == 0 && !fulfilled {
                    fulfilled = true
                    exp.fulfill()
                }
            }
            backgroundQueue.addOperation(op)
        }

        waitForExpectationsWithTimeout(10, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.grandOperator.allErrors().count, 0)
            XCTAssertEqual(
                self.grandOperator.model.folderCountByPredicate(NSPredicate.init(value: true)), 1)
            XCTAssertEqual(
                self.grandOperator.model.messageCountByPredicate(NSPredicate.init(value: true)),
                numMails)
        })
    }
}
