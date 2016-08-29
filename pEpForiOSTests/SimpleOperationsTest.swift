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
        })

        XCTAssertGreaterThan(
            self.persistentSetup.model.folderCountByPredicate(
                NSPredicate.init(value: true)), 0)
        XCTAssertGreaterThan(
            self.persistentSetup.model.messageCountByPredicate(
                NSPredicate.init(value: true)), 0)
    }

    func testFetchFoldersOperation() {
        let foldersFetched = expectationWithDescription("foldersFetched")

        let op = FetchFoldersOperation.init(
            connectInfo: connectInfo,
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
            connectionManager: persistentSetup.grandOperator.connectionManager)
        op.completionBlock = {
            foldersFetched.fulfill()
        }

        op.start()
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertGreaterThanOrEqual(
            self.persistentSetup.model.folderCountByPredicate(
                NSPredicate.init(value: true)), 1)
        XCTAssertEqual(self.persistentSetup.model.folderByName(
            ImapSync.defaultImapInboxName,
            email: self.connectInfo.email)?.name.lowercaseString,
                       ImapSync.defaultImapInboxName.lowercaseString)
        XCTAssertNotNil(persistentSetup.model.folderByType(
            .Sent, account: persistentSetup.account))
    }

    func testStorePrefetchedMailOperation() {
        persistentSetup.model.insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderSeparator: nil,
            accountEmail: connectInfo.email)
        persistentSetup.model.save()

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
                self.persistentSetup.model.messageCountByPredicate(
                    NSPredicate.init(value: true)), 1)
        })
    }

    func testStoreMultipleMails() {
        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)
        let numMails = 10

        persistentSetup.model.insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderSeparator: nil,
            accountEmail: connectInfo.email)
        persistentSetup.model.save()

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
                self.persistentSetup.model.folderCountByPredicate(
                    NSPredicate.init(value: true)), 1)
            XCTAssertEqual(
                self.persistentSetup.model.messageCountByPredicate(
                    NSPredicate.init(value: true)),
                numMails)
        })
    }

    func testCreateLocalSpecialFoldersOperation() {
        let expFoldersStored = expectationWithDescription("expFoldersStored")
        let op = CreateLocalSpecialFoldersOperation.init(
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
            accountEmail: connectInfo.email)
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
            let outbox = self.persistentSetup.model.folderByType(
                FolderType.LocalOutbox, email: self.connectInfo.email)
            XCTAssertNotNil(outbox, "Expected outbox to exist")
        })
    }

    func createBasicMail() -> (
        NSOperationQueue, IAccount, IModel, IMessage,
        (identity: NSMutableDictionary, receiver1: PEPContact,
        receiver2: PEPContact, receiver3: PEPContact,
        receiver4: PEPContact))? {
            let model = persistentSetup.model
            let opCreateSpecialFolders = CreateLocalSpecialFoldersOperation.init(
                coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
                accountEmail: connectInfo.email)
            let expFoldersStored = expectationWithDescription("expFoldersStored")
            opCreateSpecialFolders.completionBlock = {
                expFoldersStored.fulfill()
            }

            let queue = NSOperationQueue.init()
            queue.addOperation(opCreateSpecialFolders)
            waitForExpectationsWithTimeout(waitTime, handler: { error in
                XCTAssertNil(error)
            })

            guard let outboxFolder = model.folderByType(
                FolderType.LocalOutbox, email: connectInfo.email) else {
                    XCTAssertTrue(false, "Expected outbox to exist")
                    return nil
            }
            guard let message = model.insertNewMessageForSendingFromAccountEmail(
                connectInfo.email) else {
                    XCTAssertTrue(false, "Expected message to be created")
                    return nil
            }
            XCTAssertNotNil(message.from)
            XCTAssertNotNil(message.folder)

            let session = PEPSession.init()

            let (identity, receiver1, receiver2, receiver3, receiver4) =
                TestUtil.setupSomeIdentities(session)
            session.mySelf(identity)
            XCTAssertNotNil(identity[kPepFingerprint])

            // Import public key for receiver4
            TestUtil.importKeyByFileName(
                session, fileName: "5A90_3590_0E48_AB85_F3DB__045E_4623_C5D1_EAB6_643E.asc")

            message.folder = outboxFolder as! Folder

            return (queue, persistentSetup.account, model, message,
                    (identity, receiver1, receiver2, receiver3, receiver4))
    }

    func testEncryptMailOperation() {
        guard let (queue, account, model, message,
                   (identity, receiver1, _, _, receiver4)) = createBasicMail() else {
            XCTAssertTrue(false)
            return
        }

        // We can encrypt to identity (ourselves) and receiver4.
        // So we should receive 3 mails:
        // One encrypted to identity (CC), one encrypted to receiver4 (BCC),
        // and one unencrypted to receiver1 (TO).
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

        model.save()

        let encryptionData = EncryptionData.init(
            connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.coreDataUtil, coreDataMessageID: mail.objectID,
            accountEmail: account.email, outgoing: true)
        let encOp = EncryptMailOperation.init(encryptionData: encryptionData)

        let expEncrypted = expectationWithDescription("expEncrypted")
        encOp.completionBlock = {
            expEncrypted.fulfill()
        }
        queue.addOperation(encOp)
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(encryptionData.mailsToSend.count, 3)
            var encounteredBCC = false
            var encounteredCC = false
            for msg in encryptionData.mailsToSend {
                if msg[kPepBCC]?.count > 0 {
                    encounteredBCC = true
                    XCTAssertTrue(PEPUtil.isProbablyPGPMimePepMail(msg))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepTo] as? NSArray))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepCC] as? NSArray))
                } else if msg[kPepCC]?.count > 0 {
                    encounteredCC = true
                    XCTAssertTrue(PEPUtil.isProbablyPGPMimePepMail(msg))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepTo] as? NSArray))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepBCC] as? NSArray))
                } else {
                    XCTAssertFalse(PEPUtil.isProbablyPGPMimePepMail(msg))
                }
            }
            XCTAssertTrue(encounteredBCC)
            XCTAssertTrue(encounteredCC)
            XCTAssertEqual(encOp.errors.count, 0)
        })
    }

    func testSimpleDecryptMailOperation() {
        guard let (queue, account, model, message,
                   (identity, _, _, _, _)) = createBasicMail() else {
                    XCTAssertTrue(false)
                    return
        }

        let subject = "Subject"
        let longMessage = "Long Message"
        let longMessageFormatted = "<b>HTML message</b>"

        let mail = message as! Message
        mail.addToObject(
            PEPUtil.insertPepContact(identity as PEPContact, intoModel: model) as! Contact)
        mail.subject = subject
        mail.longMessage = longMessage
        mail.longMessageFormatted = longMessageFormatted

        model.save()

        let encryptionData = EncryptionData.init(
            connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.coreDataUtil, coreDataMessageID: mail.objectID,
            accountEmail: account.email, outgoing: true)
        let encOp = EncryptMailOperation.init(encryptionData: encryptionData)

        let expEncrypted = expectationWithDescription("expEncrypted")
        encOp.completionBlock = {
            expEncrypted.fulfill()
        }
        queue.addOperation(encOp)
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertEqual(encryptionData.mailsToSend.count, 1)
        PEPUtil.isProbablyPGPMimePepMail(encryptionData.mailsToSend[0])

        persistentSetup.model.deleteMail(mail)
        let inboxFolder = model.insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderSeparator: nil,
            accountEmail: account.email)

        let newMail = model.insertNewMessage()
        newMail.folder = inboxFolder as! Folder
        PEPUtil.updateWholeMessage(newMail,
                                   fromPepMail: encryptionData.mailsToSend[0], model: model)

        XCTAssertEqual(newMail.subject, "pEp")
        XCTAssertNotNil(newMail.longMessage)
        if let lm = newMail.longMessage {
            XCTAssertTrue(lm.contains("p≡p"))
        }
        XCTAssertNil(newMail.longMessageFormatted)

        let expDecrypted = expectationWithDescription("expDecrypted")
        let decrOp = DecryptMailOperation.init(
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil)
        decrOp.completionBlock = {
            expDecrypted.fulfill()
        }
        queue.addOperation(decrOp)
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNotEqual(newMail.subject, subject)
            XCTAssertNotEqual(newMail.longMessage, longMessage)
            XCTAssertNotEqual(newMail.longMessageFormatted, longMessageFormatted)
        })
    }

    func testSendMailOperation() {
        let encryptionData = EncryptionData.init(
            connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.coreDataUtil,
            // fake, but not needed for the test
            coreDataMessageID: (persistentSetup.account as! Account).objectID,
            accountEmail: persistentSetup.account.email, outgoing: true)

        let from = PEPUtil.identityFromAccount(persistentSetup.account, isMyself: true)
        let contact = NSMutableDictionary()
        contact[kPepUsername] = "Unit 001"
        contact[kPepAddress] = "unittest.ios.1@peptest.ch"

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

        waitForExpectationsWithTimeout(waitTime * 2, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(sendOp.errors.count, 0)
            XCTAssertEqual(encryptionData.mailsSent.count, numMails)
       })
    }

    /**
     It's important to always provide the correct kPepUserID for a local account ID.
     */
    func testSimpleOutgoingMailColor() {
        let session = PEPSession.init()
        let (identity, _, _, _, _) = TestUtil.setupSomeIdentities(session)
        let myself = identity.mutableCopy() as! NSMutableDictionary
        session.mySelf(myself)
        XCTAssertNotNil(myself[kPepFingerprint])

        let color2 = session.outgoingColorFrom(myself as PEPContact,
                                               to: myself as PEPContact)
        XCTAssertGreaterThanOrEqual(color2.rawValue, PEP_rating_reliable.rawValue)
    }

    func testFolderModelOperationEmpty() {
        let expFoldersLoaded = expectationWithDescription("foldersLoaded")
        let op = FolderModelOperation.init(
            account: persistentSetup.account, coreDataUtil: persistentSetup.coreDataUtil)
        op.completionBlock = {
            expFoldersLoaded.fulfill()
        }

        let backgroundQueue = NSOperationQueue.init()
        backgroundQueue.addOperation(op)

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(
                self.persistentSetup.model.folderCountByPredicate(
                    NSPredicate.init(value: true)), 0)
            XCTAssertEqual(op.folderItems.count, 0)
        })
    }

    func testFolderModelOperation() {
        let separator = "."
        let children = NSMutableOrderedSet()
        guard let parentFolder = persistentSetup.model.insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderSeparator: separator,
            accountEmail: persistentSetup.account.email) else {
                XCTAssertTrue(false)
                return
        }
        XCTAssertEqual(parentFolder.name, ImapSync.defaultImapInboxName)

        let sentFolderName = "Sent"
        let archiveFolderName = "Archive"
        let draftsFolderName = "Drafts"
        let junkFolderName = "Junk"

        let folderNames = [sentFolderName, archiveFolderName,
                           draftsFolderName, junkFolderName]
        for name in folderNames {
            if  let subFolder = persistentSetup.model.insertOrUpdateFolderName(
                name, folderSeparator: separator,
                accountEmail: persistentSetup.account.email) {
                subFolder.parent = parentFolder as? Folder
                children.addObject(subFolder)
            } else {
                XCTAssertTrue(false)
            }
        }
        parentFolder.children = children
        let expFoldersLoaded = expectationWithDescription("foldersLoaded")
        let op = FolderModelOperation.init(
            account: persistentSetup.account, coreDataUtil: persistentSetup.coreDataUtil)
        op.completionBlock = {
            expFoldersLoaded.fulfill()
        }

        let backgroundQueue = NSOperationQueue.init()
        backgroundQueue.addOperation(op)

        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(
                self.persistentSetup.model.folderCountByPredicate(
                    NSPredicate.init(value: true)), folderNames.count + 1)
            XCTAssertEqual(op.folderItems.count, folderNames.count + 1)

            XCTAssertEqual(op.folderItems[0].name, ImapSync.defaultImapInboxName)
            XCTAssertEqual(op.folderItems[0].level, 0)

            XCTAssertEqual(op.folderItems[1].name, sentFolderName)
            XCTAssertEqual(op.folderItems[1].level, 1)

            XCTAssertEqual(op.folderItems[2].name, archiveFolderName)
            XCTAssertEqual(op.folderItems[2].level, 1)

            XCTAssertEqual(op.folderItems[3].name, draftsFolderName)
            XCTAssertEqual(op.folderItems[3].level, 1)

            XCTAssertEqual(op.folderItems[4].name, junkFolderName)
            XCTAssertEqual(op.folderItems[4].level, 1)
        })
    }

    func testAppendMessageOperation() {
        // Fetch remote folders first
        testFetchFoldersOperation()

        let c1 = persistentSetup.model.insertOrUpdateContactEmail(
            "some@some.com", name: "Whatever")
        c1.addressBookID = 1

        let c2 = persistentSetup.model.insertOrUpdateContactEmail(
            "some@some2.com", name: "Whatever2")
        c2.addressBookID = 2

        let message = persistentSetup.model.insertNewMessage() as! Message
        message.subject = "Some subject"
        message.longMessage = "Long message"
        message.longMessageFormatted = "<h1>Long HTML</h1>"

        message.addToObject(c1 as! Contact)
        message.addCcObject(c2 as! Contact)

        let account = persistentSetup.model.insertAccountFromConnectInfo(connectInfo)
        let sentFolder = persistentSetup.model.folderByType(.Sent, account: account)
            as! Folder

        let op = AppendMessageOperation.init(
            message: message, account: persistentSetup.account,
            targetFolder: sentFolder,
            connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil)

        let messageAppended = expectationWithDescription("messageAppended")
        op.completionBlock = {
            messageAppended.fulfill()
        }

        op.start()
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })
    }
}