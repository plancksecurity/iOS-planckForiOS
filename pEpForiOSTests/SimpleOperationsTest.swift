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
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class SimpleOperationsTest: XCTestCase {
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
        let expCompleted = expectation(description: "expCompleted")
        let op = VerifyImapConnectionOperation.init(grandOperator: persistentSetup.grandOperator,
                                                    connectInfo: persistentSetup.connectionInfo)
        op.completionBlock = {
            expCompleted.fulfill()
        }

        OperationQueue.init().addOperation(op)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testPrefetchMailsOperation() {
        let expMailsPrefetched = expectation(description: "expMailsPrefetched")

        let op = PrefetchEmailsOperation.init(grandOperator: persistentSetup.grandOperator,
                                              connectInfo: connectInfo,
                                              folder: ImapSync.defaultImapInboxName)
        op.completionBlock = {
            expMailsPrefetched.fulfill()
        }

        op.start()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
            print(op.errors)
        })

        XCTAssertGreaterThan(
            self.persistentSetup.model.folderCountByPredicate(
                NSPredicate.init(value: true)), 0)
        XCTAssertGreaterThan(
            self.persistentSetup.model.messageCountByPredicate(
                NSPredicate.init(value: true)), 0)
    }

    func testFetchFoldersOperation() {
        let expFoldersFetched = expectation(description: "expFoldersFetched")

        let op = FetchFoldersOperation.init(
            connectInfo: connectInfo,
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
            connectionManager: persistentSetup.grandOperator.connectionManager)
        op.completionBlock = {
            expFoldersFetched.fulfill()
        }

        op.start()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertGreaterThanOrEqual(
            self.persistentSetup.model.folderCountByPredicate(
                NSPredicate.init(value: true)), 1)
        XCTAssertEqual(self.persistentSetup.model.folderByType(
            .inbox,email: self.connectInfo.email)?.name.lowercased(),
                       ImapSync.defaultImapInboxName.lowercased())
        XCTAssertNotNil(persistentSetup.model.folderByType(
            .sent, account: persistentSetup.account))
    }

    func testStorePrefetchedMailOperation() {
        let _ = persistentSetup.model.insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderSeparator: nil,
            accountEmail: connectInfo.email)
        persistentSetup.model.save()

        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)
        let message = CWIMAPMessage.init()
        message.setFrom(CWInternetAddress.init(personal: "personal", address: "somemail@test.com"))
        message.setFolder(folder)

        let expStored = expectation(description: "expStored")
        let op = StorePrefetchedMailOperation.init(
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
            accountEmail: connectInfo.email, message: message)
        op.completionBlock = {
            expStored.fulfill()
        }
        let backgroundQueue = OperationQueue.init()
        backgroundQueue.addOperation(op)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(
                self.persistentSetup.model.messageCountByPredicate(
                    NSPredicate.init(value: true)), 1)
        })
    }

    func testStoreMultipleMails() {
        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)
        let numMails = 10

        let _ = persistentSetup.model.insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderSeparator: nil,
            accountEmail: connectInfo.email)
        persistentSetup.model.save()

        let expMailsStored = expectation(description: "expMailsStored")
        var operations: Set<Operation> = []
        let backgroundQueue = OperationQueue.init()
        var fulfilled = false
        for i in 1...numMails {
            let message = CWIMAPMessage.init()
            message.setFrom(CWInternetAddress.init(personal: "personal\(i)",
                address: "somemail\(i)@test.com"))
            message.setSubject("Subject \(i)")
            message.setRecipients([CWInternetAddress.init(personal: "thisIsMe",
                address: "myaddress@test.com", type: .toRecipient)])
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
                    expMailsStored.fulfill()
                }
            }
            backgroundQueue.addOperation(op)
        }

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
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
        let expFoldersStored = expectation(description: "expFoldersStored")
        let op = CreateLocalSpecialFoldersOperation.init(
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
            accountEmail: connectInfo.email)
        let queue = OperationQueue.init()
        op.completionBlock = {
            expFoldersStored.fulfill()
        }
        queue.addOperation(op)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            guard let folders = self.persistentSetup.model.foldersByPredicate(
                NSPredicate.init(value: true), sortDescriptors: nil) else {
                    XCTAssertTrue(false, "Expected folders created")
                    return
            }
            XCTAssertEqual(folders.count, FolderType.allValuesToCreate.count)
            let outbox = self.persistentSetup.model.folderByType(
                FolderType.localOutbox, email: self.connectInfo.email)
            XCTAssertNotNil(outbox, "Expected outbox to exist")
        })
    }

    func createBasicMail() -> (
        OperationQueue, Account, ICdModel, Message,
        (identity: NSMutableDictionary, receiver1: PEPContact,
        receiver2: PEPContact, receiver3: PEPContact,
        receiver4: PEPContact))? {
            let model = persistentSetup.model
            let opCreateSpecialFolders = CreateLocalSpecialFoldersOperation.init(
                coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
                accountEmail: connectInfo.email)
            let expFoldersStored = expectation(description: "expFoldersStored")
            opCreateSpecialFolders.completionBlock = {
                expFoldersStored.fulfill()
            }

            let queue = OperationQueue.init()
            queue.addOperation(opCreateSpecialFolders)
            waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
                XCTAssertNil(error)
            })

            guard let outboxFolder = model.folderByType(
                FolderType.localOutbox, email: connectInfo.email) else {
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

            message.folder = outboxFolder

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
        let mail = message
        mail.addToObject(
            value: PEPUtil.insertPepContact(receiver1, intoModel: model))
        mail.addCcObject(
            value: PEPUtil.insertPepContact(identity as NSDictionary as! PEPContact,
                                            intoModel: model))
        mail.addBccObject(
            value: PEPUtil.insertPepContact(receiver4, intoModel: model))
        mail.subject = "Subject"
        mail.longMessage = "Long Message"
        mail.longMessageFormatted = "<b>HTML message</b>"

        model.save()

        let encryptionData = EncryptionData.init(
            connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.coreDataUtil, coreDataMessageID: mail.objectID,
            accountEmail: account.email, outgoing: true)
        let encOp = EncryptMailOperation.init(encryptionData: encryptionData)

        let expEncrypted = expectation(description: "expEncrypted")
        encOp.completionBlock = {
            expEncrypted.fulfill()
        }
        queue.addOperation(encOp)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(encryptionData.mailsToSend.count, 3)
            var encounteredBCC = false
            var encounteredCC = false
            for msg in encryptionData.mailsToSend {
                if let bccs = msg[kPepBCC] as? NSArray, bccs.count > 0 {
                    encounteredBCC = true
                    XCTAssertTrue(PEPUtil.isProbablyPGPMimePepMail(msg))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepTo] as? NSArray))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepCC] as? NSArray))
                } else if let ccs = msg[kPepCC] as? NSArray, ccs.count > 0 {
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

        let mail = message
        mail.addToObject(
            value: PEPUtil.insertPepContact(identity as NSDictionary as! PEPContact,
                                            intoModel: model))
        mail.subject = subject
        mail.longMessage = longMessage
        mail.longMessageFormatted = longMessageFormatted

        model.save()

        let encryptionData = EncryptionData.init(
            connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.coreDataUtil, coreDataMessageID: mail.objectID,
            accountEmail: account.email, outgoing: true)
        let encOp = EncryptMailOperation.init(encryptionData: encryptionData)

        let expEncrypted = expectation(description: "expEncrypted")
        encOp.completionBlock = {
            expEncrypted.fulfill()
        }
        queue.addOperation(encOp)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertEqual(encryptionData.mailsToSend.count, 1)
        XCTAssertTrue(PEPUtil.isProbablyPGPMimePepMail(encryptionData.mailsToSend[0]))

        persistentSetup.model.deleteMail(mail)
        guard let inboxFolder = model.insertOrUpdateFolderName(
            ImapSync.defaultImapInboxName, folderSeparator: nil,
            accountEmail: account.email) else {
                XCTAssertTrue(false)
                return
        }

        let newMail = model.insertNewMessage()
        newMail.folder = inboxFolder
        PEPUtil.updateWholeMessage(newMail,
                                   fromPepMail: encryptionData.mailsToSend[0], model: model)

        XCTAssertEqual(newMail.subject, "pEp")
        XCTAssertNotNil(newMail.longMessage)
        if let lm = newMail.longMessage {
            XCTAssertTrue(lm.contains("p≡p"))
        }
        XCTAssertNil(newMail.longMessageFormatted)

        let expDecrypted = expectation(description: "expDecrypted")
        let decrOp = DecryptMailOperation.init(
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil)
        decrOp.completionBlock = {
            expDecrypted.fulfill()
        }
        queue.addOperation(decrOp)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNotEqual(newMail.subject, subject)
            XCTAssertNotEqual(newMail.longMessage, longMessage)
            XCTAssertNotEqual(newMail.longMessageFormatted, longMessageFormatted)
        })
    }

    func testSendMailOperation() {
        let message = persistentSetup.model.insertNewMessage()

        let encryptionData = EncryptionData.init(
            connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.coreDataUtil,
            coreDataMessageID: message.objectID,
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
            encryptionData.mailsToSend.append(fakeMail as NSDictionary as! PEPMail)
        }

        let expMailsSent = expectation(description: "expMailsSent")

        let opSpecialFolders = CreateLocalSpecialFoldersOperation.init(
            coreDataUtil: persistentSetup.coreDataUtil,
            accountEmail: persistentSetup.account.email)

        let sendOp = SendMailOperation.init(encryptionData: encryptionData)
        sendOp.completionBlock = {
            expMailsSent.fulfill()
        }
        sendOp.addDependency(opSpecialFolders)

        let queue = OperationQueue.init()
        queue.addOperation(opSpecialFolders)
        queue.addOperation(sendOp)

        waitForExpectations(timeout: TestUtil.waitTime * 2, handler: { error in
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

        let color2 = session.outgoingColor(from: myself as NSDictionary as! PEPContact,
                                               to: myself as NSDictionary as! PEPContact)
        XCTAssertGreaterThanOrEqual(color2.rawValue, PEP_rating_reliable.rawValue)
    }

    func testFolderModelOperationEmpty() {
        let expFoldersLoaded = expectation(description: "expFoldersLoaded")
        let op = FolderModelOperation.init(
            account: persistentSetup.account, coreDataUtil: persistentSetup.coreDataUtil)
        op.completionBlock = {
            expFoldersLoaded.fulfill()
        }

        let backgroundQueue = OperationQueue.init()
        backgroundQueue.addOperation(op)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
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
                subFolder.parent = parentFolder
                children.add(subFolder)
            } else {
                XCTAssertTrue(false)
            }
        }
        parentFolder.children = children
        let expFoldersLoaded = expectation(description: "expFoldersLoaded")
        let op = FolderModelOperation.init(
            account: persistentSetup.account, coreDataUtil: persistentSetup.coreDataUtil)
        op.completionBlock = {
            expFoldersLoaded.fulfill()
        }

        let backgroundQueue = OperationQueue.init()
        backgroundQueue.addOperation(op)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
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

        let expCreated = expectation(description: "expCreated")
        let opCreate = CheckAndCreateFolderOfTypeOperation.init(
            account: persistentSetup.account, folderType: .drafts,
            connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.coreDataUtil)
        opCreate.completionBlock = {
            expCreated.fulfill()
        }

        let backgroundQueue = OperationQueue.init()
        backgroundQueue.addOperation(opCreate)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opCreate.hasErrors())
        })

        let c1 = persistentSetup.model.insertOrUpdateContactEmail(
            "some@some.com", name: "Whatever")
        c1.addressBookID = 1

        let c2 = persistentSetup.model.insertOrUpdateContactEmail(
            "some@some2.com", name: "Whatever2")
        c2.addressBookID = 2

        let message = persistentSetup.model.insertNewMessage()
        message.subject = "Some subject"
        message.longMessage = "Long message"
        message.longMessageFormatted = "<h1>Long HTML</h1>"

        message.addToObject(value: c1)
        message.addCcObject(value: c2)

        let account = persistentSetup.model.insertAccountFromConnectInfo(connectInfo)
        guard let targetFolder = persistentSetup.model.folderByType(
            .drafts, account: account) else {
                XCTAssertFalse(true)
                return
        }

        let op = AppendSingleMessageOperation.init(
            message: message, account: persistentSetup.account,
            targetFolder: targetFolder,
            connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil)

        let expMessageAppended = expectation(description: "expMessageAppended")
        op.completionBlock = {
            expMessageAppended.fulfill()
        }

        op.start()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })
    }

    func testSyncFlagsToServerOperationEmpty() {
        testPrefetchMailsOperation()

        guard let inbox = persistentSetup.model.folderByType(
            .inbox, email: persistentSetup.accountEmail) else {
                XCTAssertTrue(false)
                return
        }
        let op = SyncFlagsToServerOperation.init(
            folder: inbox, connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil)
        let expEmailsSynced = expectation(description: "expEmailsSynced")
        op.completionBlock = {
            expEmailsSynced.fulfill()
        }

        op.start()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })

        XCTAssertEqual(op.numberOfMessagesSynced, 0)
    }

    func testSyncFlagsToServerOperation() {
        testPrefetchMailsOperation()

        guard let inbox = persistentSetup.model.folderByType(
            .inbox, email: persistentSetup.accountEmail) else {
                XCTAssertTrue(false)
                return
        }

        for elm in inbox.messages {
            guard let m = elm as? Message else {
                XCTAssertTrue(false)
                break
            }
            XCTAssertNotNil(m.subject)
            XCTAssertGreaterThan(m.uid.intValue, 0)
            m.flagFlagged = NSNumber.init(value: !m.flagFlagged.boolValue as Bool)
            m.updateFlags()
        }

        let op = SyncFlagsToServerOperation.init(
            folder: inbox, connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil)
        let expEmailsSynced = expectation(description: "expEmailsSynced")
        op.completionBlock = {
            expEmailsSynced.fulfill()
        }

        op.start()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })

        XCTAssertEqual(op.numberOfMessagesSynced, inbox.messages.count)
    }

    /**
     Proves that in the case of several `SyncFlagsToServerOperation`s
     scheduled very close to each other only the first will do the work,
     while the others will cancel early and not do anything.
     */
    func testSyncFlagsToServerOperationMulti() {
        testPrefetchMailsOperation()

        guard let inbox = persistentSetup.model.folderByType(
            .inbox, email: persistentSetup.accountEmail) else {
                XCTAssertTrue(false)
                return
        }

        for elm in inbox.messages {
            guard let m = elm as? Message else {
                XCTAssertTrue(false)
                break
            }
            m.flagSeen = NSNumber.init(value: !m.flagSeen.boolValue as Bool)
            m.updateFlags()
        }

        var ops = [SyncFlagsToServerOperation]()
        for _ in 1...3 {
            let op = SyncFlagsToServerOperation.init(
                folder: inbox, connectionManager: persistentSetup.connectionManager,
                coreDataUtil: persistentSetup.grandOperator.coreDataUtil)
            let expEmailsSynced = expectation(description: "expEmailsSynced")
            op.completionBlock = {
                expEmailsSynced.fulfill()
            }
            ops.append(op)
        }

        let backgroundQueue = OperationQueue.init()

        // Serialize all ops
        backgroundQueue.maxConcurrentOperationCount = 1

        for op in ops {
            backgroundQueue.addOperation(op)
        }

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            for op in ops {
                XCTAssertFalse(op.hasErrors())
            }
        })

        var first = true
        for op in ops {
            if first {
                XCTAssertEqual(op.numberOfMessagesSynced, inbox.messages.count)
                first = false
            } else {
                XCTAssertEqual(op.numberOfMessagesSynced, 0)
            }
        }
    }

    func testCreateFolders() {
        let backgroundQueue = OperationQueue.init()

        // Fetch folders to get the folder separator
        let opFetchFolders = FetchFoldersOperation.init(
            connectInfo: connectInfo,
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
            connectionManager: persistentSetup.grandOperator.connectionManager)

        let expCreated = expectation(description: "expCreated")
        let opCreate = CheckAndCreateFolderOfTypeOperation.init(
            account: persistentSetup.account, folderType: .drafts,
            connectionManager: persistentSetup.connectionManager,
            coreDataUtil: persistentSetup.coreDataUtil)
        opCreate.addDependency(opFetchFolders)
        opCreate.completionBlock = {
            expCreated.fulfill()
        }

        backgroundQueue.addOperation(opFetchFolders)
        backgroundQueue.addOperation(opCreate)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opFetchFolders.hasErrors())
            XCTAssertFalse(opCreate.hasErrors())
        })

        XCTAssertNotNil(persistentSetup.model.folderByType(
            .drafts, email: persistentSetup.account.email))
    }

    func testDeleteFolderOperation() {
        testCreateFolders()

        let backgroundQueue = OperationQueue.init()
        guard let folder = persistentSetup.model.folderByType(
            .drafts, email: persistentSetup.account.email) else {
                XCTAssertTrue(false)
                return
        }

        let expDeleted = expectation(description: "expDeleted")
        let opDelete = DeleteFolderOperation.init(
            accountEmail: persistentSetup.account.email,
            folderName: folder.name, coreDataUtil: persistentSetup.coreDataUtil,
            connectionManager: persistentSetup.connectionManager)
        opDelete.completionBlock = {
            expDeleted.fulfill()
        }

        backgroundQueue.addOperation(opDelete)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opDelete.hasErrors())
            print(opDelete.errors)
        })

        XCTAssertNil(persistentSetup.model.folderByType(
            .drafts, email: persistentSetup.account.email))
    }
}
