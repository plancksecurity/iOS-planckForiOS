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

    var persistentSetup: PersistentSetup!
    var grandOperator: IGrandOperator!
    var connectInfo: ConnectInfo!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup.init()
        grandOperator = GrandOperator.init(connectionManager: ConnectionManager.init(),
                                           coreDataUtil: persistentSetup.coreDataUtil)
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
                self.grandOperator.operationModel().folderCountByPredicate(NSPredicate.init(value: true)), 0)
            XCTAssertGreaterThan(
                self.grandOperator.operationModel().messageCountByPredicate(NSPredicate.init(value: true)), 0)
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
                self.grandOperator.operationModel().folderCountByPredicate(NSPredicate.init(value: true)), 1)
            XCTAssertEqual(self.grandOperator.operationModel().folderByName(
                ImapSync.defaultImapInboxName, email: self.connectInfo.email)?.name.lowercaseString,
                ImapSync.defaultImapInboxName.lowercaseString)
        })
    }

    func testStoreSingleMail() {
        grandOperator.operationModel().insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderType: Account.AccountType.IMAP,
            accountEmail: connectInfo.email)
        grandOperator.operationModel().save()

        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)
        let message = CWIMAPMessage.init()
        message.setFrom(CWInternetAddress.init(personal: "personal", address: "somemail@test.com"))
        message.setFolder(folder)
        let op = StorePrefetchedMailOperation.init(grandOperator: self.grandOperator,
                                                   accountEmail: connectInfo.email,
                                                   message: message)
        let backgroundQueue = NSOperationQueue.init()
        backgroundQueue.addOperation(op)
        backgroundQueue.waitUntilAllOperationsAreFinished()
        XCTAssertEqual(
            self.grandOperator.operationModel().messageCountByPredicate(NSPredicate.init(value: true)), 1)
    }

    func testStoreMultipleMails() {
        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)
        let numMails = 10

        grandOperator.operationModel().insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderType: Account.AccountType.IMAP,
            accountEmail: connectInfo.email)
        grandOperator.operationModel().save()

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
                                                       message: message)
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

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.grandOperator.allErrors().count, 0)
            XCTAssertEqual(
                self.grandOperator.operationModel().folderCountByPredicate(NSPredicate.init(value: true)), 1)
            XCTAssertEqual(
                self.grandOperator.operationModel().messageCountByPredicate(NSPredicate.init(value: true)),
                numMails)
        })
    }

    func testFetchSingleMailsOperationSimple() {
        testPrefetchMailsOperation()
        let mails = grandOperator.operationModel().messagesByPredicate(NSPredicate.init(value: true))
        let mail = mails![0] as! Message

        let mailFetched = expectationWithDescription("mailFetched")

        let op = FetchMailOperation.init(grandOperator: grandOperator,
                                         connectInfo: connectInfo,
                                         folderName: ImapSync.defaultImapInboxName,
                                         uid: mail.uid!.integerValue)
        op.completionBlock = {
            mailFetched.fulfill()
        }
        op.start()

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertGreaterThan(
                self.grandOperator.operationModel().folderCountByPredicate(NSPredicate.init(value: true)), 0)
            XCTAssertGreaterThan(
                self.grandOperator.operationModel().messageCountByPredicate(NSPredicate.init(value: true)), 0)
            let message = self.grandOperator.operationModel().messageByPredicate(
                NSPredicate.init(format: "uid = %d", mail.uid!.integerValue))
            XCTAssertNotNil(message)
            let hasTextMessage = message?.longMessage != nil
            let hasHtml = message?.longMessageFormatted != nil
            let hasAttachments = message?.attachments.count > 0
            XCTAssertTrue(hasTextMessage || hasHtml || hasAttachments)
        })
    }

    func testFetchSingleMailsOperationChained() {
        let mailFetched = expectationWithDescription("mailFetched")
        let mailsPrefetched = expectationWithDescription("mailsPrefetched")

        let op1 = PrefetchEmailsOperation.init(grandOperator: grandOperator,
                                              connectInfo: connectInfo,
                                              folder: ImapSync.defaultImapInboxName)
        op1.completionBlock = {
            mailsPrefetched.fulfill()
        }

        // TODO: Chain in another operation to find out an existing UID
        let op2 = FetchMailOperation.init(grandOperator: grandOperator,
                                          connectInfo: connectInfo,
                                          folderName: ImapSync.defaultImapInboxName,
                                          uid: 10)
        op2.completionBlock = {
            mailFetched.fulfill()
        }

        op2.addDependency(op1)
        let queue = NSOperationQueue.init()
        queue.addOperation(op1)
        queue.addOperation(op2)

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertGreaterThan(
                self.grandOperator.operationModel().folderCountByPredicate(NSPredicate.init(value: true)), 0)
            XCTAssertGreaterThan(
                self.grandOperator.operationModel().messageCountByPredicate(NSPredicate.init(value: true)), 0)
        })
    }
}
