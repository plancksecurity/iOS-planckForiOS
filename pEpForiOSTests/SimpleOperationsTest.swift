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
    let waitTime: NSTimeInterval = 1000

    var persistentSetup: PersistentSetup!
    var connectInfo: ConnectInfo!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup.init()
        connectInfo = TestData.connectInfo
        TestUtil.adjustBaseLevel()
    }

    override func tearDown() {
        persistentSetup = nil
        TestUtil.waitForServiceShutdown()
        super.tearDown()
    }

    func testVerifyConnection() {
        let expCompleted = expectationWithDescription("completed")
        let op = VerifyImapConnectionOperation.init(grandOperator: persistentSetup.grandOperator,
                                                    connectInfo: persistentSetup.connectionInfo)
        op.completionBlock = {
            expCompleted.fulfill()
        }

        NSOperationQueue.init().addOperation(op)

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testPrefetchMailsOperation() {
        let mailsPrefetched = expectationWithDescription("mailsPrefetched")

        let op = PrefetchEmailsOperation.init(grandOperator: persistentSetup.grandOperator,
                                              connectInfo: connectInfo,
                                              folder: ImapSync.defaultImapInboxName)
        op.completionBlock = {
            mailsPrefetched.fulfill()
        }

        op.start()
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertGreaterThan(
                self.persistentSetup.grandOperator.operationModel().folderCountByPredicate(
                    NSPredicate.init(value: true)), 0)
            XCTAssertGreaterThan(
                self.persistentSetup.grandOperator.operationModel().messageCountByPredicate(
                    NSPredicate.init(value: true)), 0)
        })
    }

    func testFetchFoldersOperation() {
        let foldersFetched = expectationWithDescription("foldersFetched")

        let op = FetchFoldersOperation.init(grandOperator: persistentSetup.grandOperator,
                                            connectInfo: connectInfo)
        op.completionBlock = {
            foldersFetched.fulfill()
        }

        op.start()
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertGreaterThanOrEqual(
                self.persistentSetup.grandOperator.operationModel().folderCountByPredicate(
                    NSPredicate.init(value: true)), 1)
            XCTAssertEqual(self.persistentSetup.grandOperator.operationModel().folderByName(
                ImapSync.defaultImapInboxName,
                email: self.connectInfo.email)?.name.lowercaseString,
                ImapSync.defaultImapInboxName.lowercaseString)
        })
    }

    func testStoreSingleMail() {
        persistentSetup.grandOperator.operationModel().insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderType: Account.AccountType.IMAP,
            accountEmail: connectInfo.email)
        persistentSetup.grandOperator.operationModel().save()

        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)
        let message = CWIMAPMessage.init()
        message.setFrom(CWInternetAddress.init(personal: "personal", address: "somemail@test.com"))
        message.setFolder(folder)
        let op = StorePrefetchedMailOperation.init(
            grandOperator: self.persistentSetup.grandOperator,
            accountEmail: connectInfo.email, message: message)
        let backgroundQueue = NSOperationQueue.init()
        backgroundQueue.addOperation(op)
        XCTAssertEqual(
            self.persistentSetup.grandOperator.operationModel().messageCountByPredicate(
                NSPredicate.init(value: true)), 1)
    }

    func testStoreMultipleMails() {
        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)
        let numMails = 10

        persistentSetup.grandOperator.operationModel().insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderType: Account.AccountType.IMAP,
            accountEmail: connectInfo.email)
        persistentSetup.grandOperator.operationModel().save()

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
            let op = StorePrefetchedMailOperation.init(
                grandOperator: self.persistentSetup.grandOperator,
                accountEmail: connectInfo.email, message: message)
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
            XCTAssertEqual(self.persistentSetup.grandOperator.allErrors().count, 0)
            XCTAssertEqual(
                self.persistentSetup.grandOperator.operationModel().folderCountByPredicate(
                    NSPredicate.init(value: true)), 1)
            XCTAssertEqual(
                self.persistentSetup.grandOperator.operationModel().messageCountByPredicate(
                    NSPredicate.init(value: true)),
                numMails)
        })
    }

    func testFetchSingleMailsOperationSimple() {
        testPrefetchMailsOperation()
        let mails = persistentSetup.grandOperator.operationModel().messagesByPredicate(
            NSPredicate.init(value: true), sortDescriptors: nil)
        if mails?.count > 0 {
            let mail = mails![0] as! Message

            let mailFetched = expectationWithDescription("mailFetched")

            let op = FetchMailOperation.init(
                grandOperator: persistentSetup.grandOperator,
                connectInfo: connectInfo, folderName: ImapSync.defaultImapInboxName,
                uid: UInt(bitPattern: mail.uid!.integerValue))
            op.completionBlock = {
                mailFetched.fulfill()
            }
            op.start()

            waitForExpectationsWithTimeout(waitTime, handler: { error in
                XCTAssertNil(error)
                XCTAssertGreaterThan(
                    self.persistentSetup.grandOperator.operationModel().folderCountByPredicate(
                        NSPredicate.init(value: true)), 0)
                XCTAssertGreaterThan(
                    self.persistentSetup.grandOperator.operationModel().messageCountByPredicate(
                        NSPredicate.init(value: true)), 0)
                let message = self.persistentSetup.grandOperator.operationModel().messageByPredicate(
                    NSPredicate.init(format: "uid = %d", mail.uid!.integerValue),
                    sortDescriptors: nil)
                XCTAssertNotNil(message)
                let hasTextMessage = message?.longMessage != nil
                let hasHtml = message?.longMessageFormatted != nil
                let hasAttachments = message?.attachments.count > 0
                XCTAssertTrue(hasTextMessage || hasHtml || hasAttachments)
            })
        } else {
            XCTAssertTrue(false, "Expected mails")
        }
    }

    func testFetchSingleMailsOperationChained() {
        let mailFetched = expectationWithDescription("mailFetched")
        let mailsPrefetched = expectationWithDescription("mailsPrefetched")

        let op1 = PrefetchEmailsOperation.init(
            grandOperator: persistentSetup.grandOperator, connectInfo: connectInfo,
            folder: ImapSync.defaultImapInboxName)
        op1.completionBlock = {
            mailsPrefetched.fulfill()
        }

        let op2 = FetchMailOperation.init(
            grandOperator: persistentSetup.grandOperator, connectInfo: connectInfo,
            folderName: ImapSync.defaultImapInboxName, uid: TestData.existingUID)
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
                self.persistentSetup.grandOperator.operationModel().folderCountByPredicate(
                    NSPredicate.init(value: true)), 0)
            XCTAssertGreaterThan(
                self.persistentSetup.grandOperator.operationModel().messageCountByPredicate(
                    NSPredicate.init(value: true)), 0)
        })
    }
}
