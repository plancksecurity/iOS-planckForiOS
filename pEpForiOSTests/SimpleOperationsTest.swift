///
//  SimpleOperationsTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

import pEpForiOS
import MessageModel

class SimpleOperationsTest: XCTestCase {
    let grandOperator = GrandOperator()
    var account: CdAccount!
    var persistentSetup: PersistentSetup!

    var connectInfo: EmailConnectInfo! {
        guard let theConnectInfo = (account.emailConnectInfos.filter {
            $0.key.emailProtocol == .imap }.first?.key) else {
                XCTAssertTrue(false)
                return nil
        }
        return theConnectInfo
    }

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()

        let cdAccount = TestData().createWorkingCdAccount()
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.account = cdAccount
    }

    override func tearDown() {
        persistentSetup = nil
        super.tearDown()
    }

    func testVerifyConnection() {
        let expCompleted = expectation(description: "expCompleted")
        let op = VerifyImapConnectionOperation(grandOperator: grandOperator,
                                               connectInfo: connectInfo)
        op.completionBlock = {
            expCompleted.fulfill()
        }

        OperationQueue.init().addOperation(op)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testPrefetchMailsOperation() {
        XCTAssertNil(CdMessage.all())

        let expMailsPrefetched = expectation(description: "expMailsPrefetched")

        let op = PrefetchEmailsOperation(grandOperator: grandOperator,
                                         connectInfo: connectInfo,
                                         folder: ImapSync.defaultImapInboxName)
        op.completionBlock = {
            expMailsPrefetched.fulfill()
        }

        op.start()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })

        XCTAssertGreaterThan(
            CdFolder.countBy(predicate: NSPredicate.init(value: true)), 0)
        XCTAssertGreaterThan(
            CdMessage.all()?.count ?? 0, 0)

        guard let allMessages = CdMessage.all() as? [CdMessage] else {
            XCTFail()
            return
        }

        // Check for duplicates
        for m in allMessages {
            XCTAssertNotNil(m.uid)
            XCTAssertGreaterThan(m.uid, 0)
            guard let folder = m.parent else {
                XCTFail()
                break
            }
            XCTAssertEqual(folder.name?.lowercased(), ImapSync.defaultImapInboxName.lowercased())
            guard let messages = CdMessage.all(
                with: ["uid": m.uid, "parent": folder]) as? [CdMessage] else {
                    XCTFail()
                    break
            }
            XCTAssertEqual(messages.count, 1)
        }
    }

    func testFetchFoldersOperation() {
        let expFoldersFetched = expectation(description: "expFoldersFetched")

        let op = FetchFoldersOperation(
            connectInfo: connectInfo,
            connectionManager: grandOperator.connectionManager)
        op.completionBlock = {
            expFoldersFetched.fulfill()
        }

        op.start()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertGreaterThanOrEqual(
            CdFolder.countBy(predicate: NSPredicate.init(value: true)), 1)

        var options: [String: Any] = ["folderType": FolderType.inbox.rawValue,
                                      "account": account]
        let inboxFolder = CdFolder.first(with: options)
        options["folderType"] = FolderType.sent.rawValue
        XCTAssertNotNil(inboxFolder)
        XCTAssertEqual(inboxFolder?.name?.lowercased(),
                       ImapSync.defaultImapInboxName.lowercased())

        let sentFolder = CdFolder.first(with: options)
        XCTAssertNotNil(sentFolder)
    }

    func testStorePrefetchedMailOperation() {
        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)

        let _ = CdFolder.insertOrUpdate(
            folderName: folder.name(), folderSeparator: nil, account: account)
        Record.saveAndWait()

        let message = CWIMAPMessage.init()
        message.setFrom(CWInternetAddress.init(personal: "personal", address: "somemail@test.com"))
        message.setFolder(folder)
        message.setMessageID("001@whatever.test")

        let expStored = expectation(description: "expStored")
        let op = StorePrefetchedMailOperation(
            connectInfo: connectInfo, message: message, quick: false)
        op.completionBlock = {
            expStored.fulfill()
        }
        let backgroundQueue = OperationQueue.init()
        backgroundQueue.addOperation(op)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })

        XCTAssertEqual(CdMessage.all()?.count, 1)
    }

    func testStoreMultipleMails() {
        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)
        let numMails = 10
        var numberOfCallbacksCalled = 0

        let _ = CdFolder.insertOrUpdate(
            folderName: folder.name(), folderSeparator: nil, account: account)
        Record.saveAndWait()
        XCTAssertEqual(CdFolder.countBy(predicate: NSPredicate.init(value: true)), 1)

        let expMailsStored = expectation(description: "expMailsStored")
        let backgroundQueue = OperationQueue.init()
        for i in 1...numMails {
            let message = CWIMAPMessage.init()
            message.setFrom(CWInternetAddress.init(personal: "personal\(i)",
                address: "somemail\(i)@test.com"))
            message.setSubject("Subject \(i)")
            message.setRecipients([CWInternetAddress.init(personal: "thisIsMe",
                address: "myaddress@test.com", type: .toRecipient)])
            message.setFolder(folder)
            message.setUID(UInt(i))
            message.setMessageID("\(i)@whatever.test")
            let op = StorePrefetchedMailOperation(connectInfo: connectInfo, message: message,
                                                  quick: i % 2 == 0)
            op.completionBlock = {
                numberOfCallbacksCalled += 1
                XCTAssertEqual(op.errors.count, 0)
                if numberOfCallbacksCalled == numMails {
                    expMailsStored.fulfill()
                }
            }
            backgroundQueue.addOperation(op)
        }

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(numberOfCallbacksCalled, numMails)
        })

        XCTAssertEqual(CdMessage.all()?.count, numMails)
    }

    func testCreateLocalSpecialFoldersOperation() {
        let expFoldersStored = expectation(description: "expFoldersStored")
        let op = CreateLocalSpecialFoldersOperation(account: account)
        let queue = OperationQueue()
        op.completionBlock = {
            expFoldersStored.fulfill()
        }
        queue.addOperation(op)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            guard let folders = CdFolder.all() as? [CdFolder] else {
                    XCTAssertTrue(false, "Expected folders created")
                    return
            }
            XCTAssertEqual(folders.count, FolderType.allValuesToCreate.count)
            let p = NSPredicate(format: "folderType = %d and account = %@",
                                FolderType.localOutbox.rawValue, self.account)
            let outbox = CdFolder.first(with: p)
            XCTAssertNotNil(outbox, "Expected outbox to exist")
        })
    }

    func testCreateFolders() {
        let backgroundQueue = OperationQueue.init()

        // Fetch folders to get the folder separator
        let opFetchFolders = FetchFoldersOperation(
            connectInfo: connectInfo,
            connectionManager: grandOperator.connectionManager)

        let expCreated = expectation(description: "expCreated")
        let opCreate = CheckAndCreateFolderOfTypeOperation(
            connectInfo: connectInfo, account: account, folderType: .drafts,
            connectionManager: grandOperator.connectionManager)
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

        XCTAssertNotNil(CdFolder.by(folderType: .drafts, account: account))
    }

    func testAppendMessageOperation() {
        // Fetch remote folders first
        testFetchFoldersOperation()

        let expCreated = expectation(description: "expCreated")
        let opCreate = CheckAndCreateFolderOfTypeOperation(
            connectInfo: connectInfo, account: account, folderType: .drafts,
            connectionManager: grandOperator.connectionManager)
        opCreate.completionBlock = {
            expCreated.fulfill()
        }

        let backgroundQueue = OperationQueue.init()
        backgroundQueue.addOperation(opCreate)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opCreate.hasErrors())
        })
        
        let c1 = CdIdentity.create()
        let c2 = CdIdentity.create()
        c1.address = "user1@example.com"
        c2.address = "user2@example.com"

        let message = CdMessage.create(messageID: "#1", uid: 1)
        message.shortMessage = "Some subject"
        message.longMessage = "Long message"
        message.longMessageFormatted = "<h1>Long HTML</h1>"

        message.addTo(identity: c1)
        message.addCc(identity: c2)

        Record.saveAndWait()

        guard let targetFolder = CdFolder.by(folderType: .drafts, account: account) else {
            XCTFail()
            return
        }

        let op = AppendSingleMessageOperation(
            connectInfo: connectInfo,
            message: message, account: account, targetFolder: targetFolder,
            connectionManager: grandOperator.connectionManager)

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

    func testDeleteFolderOperation() {
        testCreateFolders()

        let backgroundQueue = OperationQueue.init()
        guard let folder = CdFolder.by(folderType: .drafts, account: account) else {
                XCTFail()
                return
        }

        let expDeleted = expectation(description: "expDeleted")
        guard let opDelete = DeleteFolderOperation(
            connectInfo: connectInfo, folder: folder,
            connectionManager: grandOperator.connectionManager) else {
                XCTFail()
                return
        }
        opDelete.completionBlock = {
            expDeleted.fulfill()
        }

        backgroundQueue.addOperation(opDelete)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opDelete.hasErrors())
        })

        XCTAssertNil(CdFolder.by(folderType: .drafts, account: account))

        // Recreate drafts folder
        testCreateFolders()
        XCTAssertNotNil(CdFolder.by(folderType: .drafts, account: account))
    }

    func testSyncFlagsToServerOperationEmpty() {
        testPrefetchMailsOperation()

        guard let inbox = CdFolder.by(folderType: .inbox, account: account) else {
            XCTFail()
            return
        }
        guard let op = SyncFlagsToServerOperation(
            connectInfo: connectInfo, folder: inbox,
            connectionManager: grandOperator.connectionManager) else {
                XCTFail()
                return
        }
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

        guard let inbox = CdFolder.by(folderType: .inbox, account: account) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            imap.flagFlagged = !imap.flagFlagged
            m.updateFlags()
        }

        Record.saveAndWait()

        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertNotNil(messagesToBeSynced)
        XCTAssertEqual(messagesToBeSynced?.count, messages.count)

        guard let op = SyncFlagsToServerOperation(
            connectInfo: connectInfo, folder: inbox,
            connectionManager: grandOperator.connectionManager) else {
                XCTFail()
                return
        }

        let expEmailsSynced = expectation(description: "expEmailsSynced")
        op.completionBlock = {
            expEmailsSynced.fulfill()
        }

        op.start()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0)
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count)
    }

    /**
     Proves that in the case of several `SyncFlagsToServerOperation`s
     scheduled very close to each other only the first will do the work,
     while the others will cancel early and not do anything.
     */
    func testSyncFlagsToServerOperationMulti() {
        testPrefetchMailsOperation()

        guard let inbox = CdFolder.by(folderType: .inbox, account: account) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        for m in messages {
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            imap.flagSeen = !imap.flagSeen
            m.updateFlags()
        }

        Record.saveAndWait()

        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)?.count ?? 0
        XCTAssertEqual(messagesToBeSynced, messages.count)

        var ops = [SyncFlagsToServerOperation]()
        for i in 1...1 {
            guard let op = SyncFlagsToServerOperation(
                connectInfo: connectInfo, folder: inbox,
                connectionManager: grandOperator.connectionManager) else {
                    XCTFail()
                    return
            }
            let expEmailsSynced = expectation(description: "expEmailsSynced\(i)")
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

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)?.count ?? 0
        XCTAssertEqual(messagesToBeSynced, 0)

        var first = true
        for op in ops {
            if first {
                XCTAssertEqual(op.numberOfMessagesSynced, inbox.messages?.count)
                first = false
            } else {
                XCTAssertEqual(op.numberOfMessagesSynced, 0)
            }
        }
    }

    func insertNewMessageForSending(account: CdAccount) -> CdMessage {
        let msg = CdMessage.create(messageID: "1@1", uid: 1)
        msg.from = account.identity
        msg.longMessage = "Inserted by insertNewMessageForSending()"
        msg.bodyFetched = true
        msg.parent = CdFolder.by(folderType: .localOutbox, account: account)
        XCTAssertNotNil(msg.from)
        XCTAssertNotNil(msg.parent)
        return msg
    }

    func createBasicMail() -> (
        OperationQueue, CdMessage,
        (identity: NSMutableDictionary, receiver1: PEPContact,
        receiver2: PEPContact, receiver3: PEPContact,
        receiver4: PEPContact)) {
            let opCreateSpecialFolders = CreateLocalSpecialFoldersOperation(account: account)
            let expFoldersStored = expectation(description: "expFoldersStored")
            opCreateSpecialFolders.completionBlock = {
                expFoldersStored.fulfill()
            }

            let queue = OperationQueue.init()
            queue.addOperation(opCreateSpecialFolders)
            waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
                XCTAssertNil(error)
            })

            let message = insertNewMessageForSending(account: account)

            let session = PEPSession.init()

            let (identity, receiver1, receiver2, receiver3, receiver4) =
                TestUtil.setupSomeIdentities(session)
            session.mySelf(identity)
            XCTAssertNotNil(identity[kPepFingerprint])

            // Import public key for receiver4
            TestUtil.importKeyByFileName(
                session, fileName: "5A90_3590_0E48_AB85_F3DB__045E_4623_C5D1_EAB6_643E.asc")

            Record.saveAndWait()
            return (queue, message, (identity, receiver1, receiver2, receiver3, receiver4))
    }

    func dumpAllAccounts() {
        let cdAccounts = CdAccount.all() as? [CdAccount]
        if let accs = cdAccounts {
            for acc in accs {
                print("\(acc.identity?.address) \(acc.identity?.userName)")
            }
        }
    }

    func testEncryptMailOperation() {
        let (queue, mail, ids) = createBasicMail()
        let (identity, receiver1, _, _, receiver4) = ids

        // We can encrypt to identity (ourselves) and receiver4.
        // So we should receive 3 mails:
        // One encrypted to identity (CC), one encrypted to receiver4 (BCC),
        // and one unencrypted to receiver1 (TO).
        mail.addTo(identity: CdIdentity.firstOrCreate(pEpContact: receiver1))
        mail.addCc(identity: CdIdentity.firstOrCreate(dictionary: identity))
        mail.addBcc(identity: CdIdentity.firstOrCreate(pEpContact: receiver4))
        mail.shortMessage = "Subject"
        mail.longMessage = "Long Message"
        mail.longMessageFormatted = "<b>HTML message</b>"

        dumpAllAccounts()
        Record.saveAndWait()

        let encryptionData = EncryptionData(
            connectionManager: grandOperator.connectionManager, messageID: mail.objectID,
            outgoing: true)
        let encOp = EncryptMailOperation(encryptionData: encryptionData)

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
        let (queue, mail, ids) = createBasicMail()
        let (identity, _, _, _, _) = ids

        let subject = "Subject"
        let longMessage = "Long Message"
        let longMessageFormatted = "<b>HTML message</b>"

        mail.addTo(identity: CdIdentity.firstOrCreate(dictionary: identity))
        mail.shortMessage = subject
        mail.longMessage = longMessage
        mail.longMessageFormatted = longMessageFormatted

        Record.saveAndWait()

        XCTAssertFalse((CdMessage.all(
            with: CdMessage.unencryptedMessagesPredicate()) ?? []).isEmpty)

        let encryptionData = EncryptionData(
            connectionManager: grandOperator.connectionManager, messageID: mail.objectID,
            outgoing: false)
        let encOp = EncryptMailOperation(encryptionData: encryptionData)

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

        mail.delete()
        let folder = CdFolder.firstOrCreate(
            with: ["folderType": FolderType.drafts.rawValue, "account": account, "uuid": "fake",
                   "name": "Drafts"])

        let newMail = CdMessage.create(messageID: "fake", uid: 0, parent: folder)
        XCTAssertEqual(newMail.pEpRating, PEPUtil.pEpRatingNone)

        newMail.update(pEpMail: encryptionData.mailsToSend[0])
        XCTAssertTrue(newMail.bodyFetched)

        XCTAssertEqual(newMail.pEpRating, PEPUtil.pEpRatingNone)
        XCTAssertNotEqual(newMail.shortMessage, subject)
        XCTAssertNotEqual(newMail.longMessage, longMessage)
        XCTAssertNil(newMail.longMessageFormatted)
        XCTAssertEqual(newMail.shortMessage, "pEp")
        XCTAssertNotNil(newMail.longMessage)
        if let lm = newMail.longMessage {
            XCTAssertTrue(lm.contains("p≡p"))
        } else {
            XCTFail()
        }

        Record.saveAndWait()

        XCTAssertFalse((CdMessage.all(
            with: CdMessage.unencryptedMessagesPredicate()) ?? []).isEmpty)

        let expDecrypted = expectation(description: "expDecrypted")
        let decrOp = DecryptMailOperation()
        decrOp.completionBlock = {
            expDecrypted.fulfill()
        }
        queue.addOperation(decrOp)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertEqual(decrOp.numberOfMessagesDecrypted, 1)
        newMail.managedObjectContext!.refresh(newMail, mergeChanges: true)
        XCTAssertEqual(newMail.shortMessage, subject)
        XCTAssertEqual(newMail.longMessage, longMessage)
        XCTAssertEqual(newMail.longMessageFormatted, longMessageFormatted)
    }

    /*
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
                CdFolder.countBy(predicate: NSPredicate.init(value: true)), 0)
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
                CdFolder.countBy(predicate: NSPredicate.init(value: true)), folderNames.count + 1)
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
     */
}
