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
    }

    override func tearDown() {
        persistentSetup = nil
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
                address: "myaddress@test.com", type: .ToRecipient)])
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
        guard let account = persistentSetup.model.insertAccountFromConnectInfo(connectInfo) else {
            XCTAssertTrue(false, "Expected account to be created")
            return
        }
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
            guard let folders = self.persistentSetup.model.foldersByPredicate(
                NSPredicate.init(value: true), sortDescriptors: nil) else {
                    XCTAssertTrue(false, "Expected folders created")
                    return
            }
            XCTAssertEqual(folders.count, FolderType.allValuesToCreate.count)
            let outbox = self.persistentSetup.model.folderLocalOutboxForEmail(account.email)
            XCTAssertNotNil(outbox, "Expected outbox to exist")
        })
    }

    func testEncryptMailOperation() {
        guard let account = persistentSetup.model.insertAccountFromConnectInfo(connectInfo) else {
            XCTAssertTrue(false, "Expected account to be created")
            return
        }

        let model = persistentSetup.model
        let op = CreateLocalSpecialFoldersOperation.init(
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
            accountEmail: account.email)
        let expFoldersStored = expectationWithDescription("expFoldersStored")
        op.completionBlock = {
            expFoldersStored.fulfill()
        }

        let queue = NSOperationQueue.init()
        queue.addOperation(op)
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })

        guard let outboxFolder = model.folderLocalOutboxForEmail(account.email) else {
            XCTAssertTrue(false, "Expected outbox to exist")
            return
        }
        guard var message = model.insertNewMessageForSendingFromAccountEmail(account.email) else {
            XCTAssertTrue(false, "Expected message to be created")
            return
        }
        XCTAssertNotNil(message.from)

        let session = PEPSession.init()

        let (identity, receiver1, _, _, receiver4) =
            TestUtil.setupSomeIdentities(session)
        session.mySelf(identity)
        XCTAssertNotNil(identity[kPepFingerprint])

        // Import public key for receiver4
        TestUtil.importKeyByFileName(
            session, fileName: "5A90_3590_0E48_AB85_F3DB__045E_4623_C5D1_EAB6_643E.asc")

        message.folder = outboxFolder as! Folder

        let mail = message as! Message
        mail.addToObject(
            PEPUtil.insertPepContact(receiver1, intoModel: model) as! Contact)
        mail.addCcObject(
            PEPUtil.insertPepContact(identity as PEPContact, intoModel: model) as! Contact)
        mail.addBccObject(
            PEPUtil.insertPepContact(receiver4, intoModel: model) as! Contact)
        mail.subject = "Subject"
        mail.longMessage = "Long Message"
        mail.longMessageFormatted = "<b>HTML message</b>"

        let encryptionData = EncryptionData.init(
            connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.coreDataUtil, messageID: mail.objectID,
            accountEmail: account.email, outgoing: true)
        let encOp = EncryptMailOperation.init(encryptionData: encryptionData)

        let expEncrypted = expectationWithDescription("expEncrypted")
        encOp.completionBlock = {
            expEncrypted.fulfill()
        }
        queue.addOperation(encOp)
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertGreaterThan(encryptionData.mailsToSend.count, 0)
            var encounteredBCC = false
            var encounteredCC = false
            for msg in encryptionData.mailsToSend {
                if msg[kPepBCC]?.count > 0 {
                    encounteredBCC = true
                    XCTAssertTrue(PEPUtil.isProbablyPGPMime(msg))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepTo] as? NSArray))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepCC] as? NSArray))
                } else if msg[kPepCC]?.count > 0 {
                    encounteredCC = true
                    XCTAssertTrue(PEPUtil.isProbablyPGPMime(msg))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepTo] as? NSArray))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepBCC] as? NSArray))
                } else {
                    XCTAssertFalse(PEPUtil.isProbablyPGPMime(msg))
                }
            }
            XCTAssertTrue(encounteredBCC)
            XCTAssertTrue(encounteredCC)
            XCTAssertEqual(encOp.errors.count, 0)
        })
    }

    func testSendMailOperation() {
        guard let account = persistentSetup.model.insertAccountFromConnectInfo(connectInfo) else {
            XCTAssertTrue(false, "Expected account to be created")
            return
        }
        let encryptionData = EncryptionData.init(
            connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.coreDataUtil,
            messageID: (account as! Account).objectID, // fake, but not needed for the test
            accountEmail: account.email, outgoing: true)

        let from = PEPUtil.identityFromAccount(account, isMyself: true)
        let contact = NSMutableDictionary()
        contact[kPepUsername] = "Test 001"
        contact[kPepAddress] = "test001@peptest.ch"

        // Build emails
        let numMails = 5
        for i in 1...numMails {
            let fakeMail: NSMutableDictionary = [:]
            fakeMail[kPepFrom] = from
            fakeMail[kPepOutgoing] = true
            fakeMail[kPepTo] = [contact]
            fakeMail[kPepShortMessage] = "Subject \(i)"
            fakeMail[kPepLongMessage]  = "Body \(i)"
            encryptionData.mailsToSend.append(fakeMail as PEPMail)
        }

        let expMailsSent = expectationWithDescription("expMailsSent")

        let sendOp = SendMailOperation.init(encryptionData: encryptionData)
        sendOp.completionBlock = {
            expMailsSent.fulfill()
        }
        let queue = NSOperationQueue.init()
        queue.addOperation(sendOp)

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(sendOp.errors.count, 0)
            XCTAssertEqual(encryptionData.mailsSent.count, numMails)
       })
    }
}