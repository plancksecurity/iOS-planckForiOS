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
            ImapSync.defaultImapInboxName, accountEmail: connectInfo.email)
        persistentSetup.grandOperator.operationModel().save()

        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)
        let message = CWIMAPMessage.init()
        message.setFrom(CWInternetAddress.init(personal: "personal", address: "somemail@test.com"))
        message.setFolder(folder)

        let exp = expectationWithDescription("stored")
        let op = StorePrefetchedMailOperation.init(
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
            accountEmail: connectInfo.email, message: message)
        op.completionBlock = {
            exp.fulfill()
        }
        let backgroundQueue = NSOperationQueue.init()
        backgroundQueue.addOperation(op)
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(
                self.persistentSetup.grandOperator.operationModel().messageCountByPredicate(
                    NSPredicate.init(value: true)), 1)
        })
    }

    func testStoreMultipleMails() {
        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)
        let numMails = 10

        persistentSetup.grandOperator.operationModel().insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, accountEmail: connectInfo.email)
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
                coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
                accountEmail: connectInfo.email, message: message)
            operations.insert(op)
            op.completionBlock = {
                operations.remove(op)
                XCTAssertEqual(op.errors.count, 0)
                if backgroundQueue.operationCount == 0 && !fulfilled {
                    fulfilled = true
                    exp.fulfill()
                }
            }
            backgroundQueue.addOperation(op)
        }

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(
                self.persistentSetup.grandOperator.operationModel().folderCountByPredicate(
                    NSPredicate.init(value: true)), 1)
            XCTAssertEqual(
                self.persistentSetup.grandOperator.operationModel().messageCountByPredicate(
                    NSPredicate.init(value: true)),
                numMails)
        })
    }

    func testCreateLocalSpecialFoldersOperation() {
        if let account = persistentSetup.model.insertAccountFromConnectInfo(connectInfo) {
            let expFoldersStored = expectationWithDescription("expFoldersStored")
            let op = CreateLocalSpecialFoldersOperation.init(
                coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
                accountEmail: account.email)
            let queue = NSOperationQueue.init()
            op.completionBlock = {
                expFoldersStored.fulfill()
            }
            queue.addOperation(op)
            waitForExpectationsWithTimeout(waitTime, handler: { error in
                XCTAssertNil(error)
                if let folders = self.persistentSetup.model.foldersByPredicate(
                    NSPredicate.init(value: true), sortDescriptors: nil) {
                    XCTAssertEqual(folders.count, FolderType.allValuesToCreate.count)
                } else {
                    XCTAssertTrue(false, "Expected folders created")
                }
            })
        } else {
            XCTAssertTrue(false, "Expected account to be created")
        }
    }
}
