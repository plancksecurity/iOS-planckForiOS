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
    let connectionManager = ConnectionManager()
    var account: CdAccount!
    var persistentSetup: PersistentSetup!

    var imapConnectInfo: EmailConnectInfo!
    var smtpConnectInfo: EmailConnectInfo!
    var imapSyncData: ImapSyncData!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()

        let cdAccount = TestData().createWorkingCdAccount()
        cdAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.account = cdAccount

        imapConnectInfo = account.imapConnectInfo
        smtpConnectInfo = account.smtpConnectInfo
        imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)

        XCTAssertNotNil(imapConnectInfo)
        XCTAssertNotNil(smtpConnectInfo)
    }

    override func tearDown() {
        persistentSetup = nil
    }

    func testComp() {
        let f = FetchFoldersOperation(imapSyncData: imapSyncData)
        XCTAssertEqual(f.comp, "FetchFoldersOperation")
    }

    func testVerifyConnection() {
        let expCompleted = expectation(description: "expCompleted")
        let op = VerifyImapConnectionOperation(connectionManager: connectionManager,
                                               connectInfo: imapConnectInfo)
        op.completionBlock = {
            expCompleted.fulfill()
        }

        OperationQueue().addOperation(op)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testFetchMessagesOperation() {
        XCTAssertNil(CdMessage.all())

        let expMailsPrefetched = expectation(description: "expMailsPrefetched")

        let opLogin = LoginImapOperation(imapSyncData: imapSyncData)
        let op = FetchMessagesOperation(imapSyncData: imapSyncData,
                                        folderName: ImapSync.defaultImapInboxName)
        op.addDependency(opLogin)
        op.completionBlock = {
            expMailsPrefetched.fulfill()
        }

        let bgQueue = OperationQueue()
        bgQueue.addOperation(opLogin)
        bgQueue.addOperation(op)

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

        guard let hostnameData = CWMIMEUtility.hostname() else {
            XCTFail()
            return
        }
        guard let localHostname = hostnameData.toStringWithIANACharset("UTF-8") else {
            XCTFail()
            return
        }

        // Check all messages for validity
        for m in allMessages {
            XCTAssertNotNil(m.uid)
            XCTAssertGreaterThan(m.uid, 0)
            XCTAssertNotNil(m.imap)
            XCTAssertNotNil(m.shortMessage)

            guard let uuid = m.uuid else {
                XCTFail()
                continue
            }
            XCTAssertFalse(uuid.contains(localHostname))

            XCTAssertTrue(m.longMessage != nil || m.longMessageFormatted != nil ||
                (m.attachments?.count ?? 0 > 0 && m.isProbablyPGPMime()))

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

    func testSyncMessagesOperation() {
        testFetchMessagesOperation()

        guard let folder = CdFolder.by(folderType: .inbox, account: account) else {
            XCTFail()
            return
        }

        guard let allMessages = CdMessage.all() as? [CdMessage] else {
            XCTFail()
            return
        }

        // Change all flags locally
        for m in allMessages {
            m.imap?.flagSeen = false
            XCTAssertFalse(m.imap?.flagSeen ?? true)
        }

        Record.saveAndWait()

        let expMailsSynced = expectation(description: "expMailsSynced")

        let op = SyncMessagesOperation(imapSyncData: imapSyncData, folder: folder,
                                       lastUID: folder.lastUID())
        op.completionBlock = {
            expMailsSynced.fulfill()
        }

        op.start()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })

        // Flags should be reverted to server version
        for m in allMessages {
            XCTAssertTrue(m.imap?.flagSeen ?? false)
        }
    }

    func testFetchFoldersOperation() {
        let expFoldersFetched = expectation(description: "expFoldersFetched")

        let opLogin = LoginImapOperation(imapSyncData: imapSyncData)
        let op = FetchFoldersOperation(imapSyncData: imapSyncData)
        op.completionBlock = {
            expFoldersFetched.fulfill()
        }
        op.addDependency(opLogin)

        let bgQueue = OperationQueue()
        bgQueue.addOperation(opLogin)
        bgQueue.addOperation(op)

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
            accountID: imapConnectInfo.accountObjectID, message: message, quick: false)
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
            let op = StorePrefetchedMailOperation(accountID: imapConnectInfo.accountObjectID,
                                                  message: message, quick: i % 2 == 0)
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

        let opLogin = LoginImapOperation(imapSyncData: imapSyncData)

        // Fetch folders to get the folder separator
        let opFetchFolders = FetchFoldersOperation(imapSyncData: imapSyncData)
        opFetchFolders.addDependency(opLogin)

        let expCreated = expectation(description: "expCreated")
        let opCreate = CheckAndCreateFolderOfTypeOperation(
            connectInfo: imapConnectInfo, account: account, folderType: .drafts,
            connectionManager: connectionManager)
        opCreate.addDependency(opFetchFolders)
        opCreate.completionBlock = {
            expCreated.fulfill()
        }

        backgroundQueue.addOperation(opLogin)
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
            connectInfo: imapConnectInfo, account: account, folderType: .drafts,
            connectionManager: connectionManager)
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

        message.addTo(cdIdentity: c1)
        message.addCc(cdIdentity: c2)

        Record.saveAndWait()

        guard let targetFolder = CdFolder.by(folderType: .drafts, account: account) else {
            XCTFail()
            return
        }

        let op = AppendSingleMessageOperation(
            connectInfo: imapConnectInfo,
            message: message, account: account, targetFolder: targetFolder,
            connectionManager: connectionManager)

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

    func testCreateDeleteFolderOperation() {
        let uuid1 = UUID.generate()
        let folder1 = CdFolder.create()
        folder1.account = account
        folder1.uuid = uuid1
        folder1.name = "Inbox.Folder1 \(uuid1)"

        let uuid2 = UUID.generate()
        let folder2 = CdFolder.create()
        folder2.account = account
        folder2.uuid = uuid1
        folder2.name = "Inbox.Folder2 \(uuid2)"

        Record.saveAndWait()

        let expCreated = expectation(description: "expCreated")
        let opCreate = CreateFoldersOperation(imapConnectInfo: imapConnectInfo, account: account,
                                              connectionManager: connectionManager)
        opCreate.completionBlock = {
            expCreated.fulfill()
        }

        let backgroundQueue = OperationQueue()
        backgroundQueue.addOperation(opCreate)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opCreate.hasErrors())
        })

        folder1.shouldDelete = true
        folder2.shouldDelete = true

        Record.saveAndWait()

        let expDeleted = expectation(description: "expDeleted")
        let opDelete = DeleteFoldersOperation(
            imapConnectInfo: imapConnectInfo, account: account,
            connectionManager: connectionManager)
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
        testFetchMessagesOperation()

        guard let inbox = CdFolder.by(folderType: .inbox, account: account) else {
            XCTFail()
            return
        }
        guard let op = SyncFlagsToServerOperation(
            connectInfo: imapConnectInfo, folder: inbox,
            connectionManager: connectionManager) else {
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
        testFetchMessagesOperation()

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
            connectInfo: imapConnectInfo, folder: inbox,
            connectionManager: connectionManager) else {
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
        testFetchMessagesOperation()

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
                connectInfo: imapConnectInfo, folder: inbox,
                connectionManager: connectionManager) else {
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
        (identity: NSMutableDictionary, receiver1: PEPIdentity,
        receiver2: PEPIdentity, receiver3: PEPIdentity,
        receiver4: PEPIdentity)) {
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
        mail.addTo(cdIdentity: CdIdentity.firstOrCreate(pEpContact: receiver1))
        mail.addCc(cdIdentity: CdIdentity.firstOrCreate(dictionary: identity))
        mail.addBcc(cdIdentity: CdIdentity.firstOrCreate(pEpContact: receiver4))
        mail.shortMessage = "Subject"
        mail.longMessage = "Long Message"
        mail.longMessageFormatted = "<b>HTML message</b>"

        dumpAllAccounts()
        Record.saveAndWait()

        let encryptionData = EncryptionData(
            imapConnectInfo: imapConnectInfo, smtpConnectInfo: smtpConnectInfo,
            connectionManager: connectionManager,
            messageID: mail.objectID, outgoing: true)
        let encOp = EncryptMessageOperation(encryptionData: encryptionData)

        let expEncrypted = expectation(description: "expEncrypted")
        encOp.completionBlock = {
            expEncrypted.fulfill()
        }
        queue.addOperation(encOp)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(encryptionData.messagesToSend.count, 3)
            var encounteredBCC = false
            var encounteredCC = false
            for msg in encryptionData.messagesToSend {
                if let bccs = msg[kPepBCC] as? NSArray, bccs.count > 0 {
                    encounteredBCC = true
                    XCTAssertTrue(PEPUtil.isProbablyPGPMime(pEpMessage: msg))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepTo] as? NSArray))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepCC] as? NSArray))
                } else if let ccs = msg[kPepCC] as? NSArray, ccs.count > 0 {
                    encounteredCC = true
                    XCTAssertTrue(PEPUtil.isProbablyPGPMime(pEpMessage: msg))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepTo] as? NSArray))
                    XCTAssertTrue(MiscUtil.isNilOrEmptyNSArray(msg[kPepBCC] as? NSArray))
                } else {
                    XCTAssertFalse(PEPUtil.isProbablyPGPMime(pEpMessage: msg))
                }
            }
            XCTAssertTrue(encounteredBCC)
            XCTAssertTrue(encounteredCC)
            XCTAssertEqual(encOp.errors.count, 0)
        })
    }

    func testSimpleDecryptMailOperation() {
        let (queue, message, ids) = createBasicMail()
        let (identity, _, _, _, _) = ids

        let subject = "Subject"
        let longMessage = "Long Message"
        let longMessageFormatted = "<b>HTML message</b>"

        let myself = CdIdentity.firstOrCreate(dictionary: identity)

        message.from = myself
        message.addTo(cdIdentity: myself)
        message.shortMessage = subject
        message.longMessage = longMessage
        message.longMessageFormatted = longMessageFormatted

        Record.saveAndWait()

        XCTAssertFalse((CdMessage.all(
            with: CdMessage.unencryptedMessagesPredicate()) ?? []).isEmpty)

        let encryptionData = EncryptionData(
            imapConnectInfo: imapConnectInfo, smtpConnectInfo: smtpConnectInfo,
            connectionManager: connectionManager,
            messageID: message.objectID, outgoing: true)
        let encOp = EncryptMessageOperation(encryptionData: encryptionData)

        let expEncrypted = expectation(description: "expEncrypted")
        encOp.completionBlock = {
            expEncrypted.fulfill()
        }
        queue.addOperation(encOp)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(encOp.hasErrors())
        })

        XCTAssertEqual(encryptionData.messagesToSend.count, 1)
        XCTAssertTrue(PEPUtil.isProbablyPGPMime(pEpMessage: encryptionData.messagesToSend[0]))

        message.delete()
        let folder = CdFolder.firstOrCreate(
            with: ["folderType": FolderType.drafts.rawValue, "account": account, "uuid": "fake",
                   "name": "Drafts"])

        let newMessage = CdMessage.create(messageID: "fake", uid: 0, parent: folder)
        XCTAssertEqual(newMessage.pEpRating, PEPUtil.pEpRatingNone)

        newMessage.update(pEpMessage: encryptionData.messagesToSend[0])
        XCTAssertTrue(newMessage.bodyFetched)

        XCTAssertEqual(newMessage.pEpRating, PEPUtil.pEpRatingNone)
        XCTAssertNotEqual(newMessage.shortMessage, subject)
        XCTAssertNotEqual(newMessage.longMessage, longMessage)
        XCTAssertNil(newMessage.longMessageFormatted)
        XCTAssertEqual(newMessage.shortMessage, "pEp")
        XCTAssertNotNil(newMessage.longMessage)
        if let lm = newMessage.longMessage {
            XCTAssertTrue(lm.contains("p≡p"))
        } else {
            XCTFail()
        }

        Record.saveAndWait()

        XCTAssertFalse((CdMessage.all(
            with: CdMessage.unencryptedMessagesPredicate()) ?? []).isEmpty)

        let expDecrypted = expectation(description: "expDecrypted")
        let decrOp = DecryptMessageOperation()
        decrOp.completionBlock = {
            expDecrypted.fulfill()
        }
        queue.addOperation(decrOp)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertEqual(decrOp.numberOfMessagesDecrypted, 1)
        newMessage.managedObjectContext!.refresh(newMessage, mergeChanges: true)
        XCTAssertEqual(newMessage.shortMessage, subject)
        XCTAssertEqual(newMessage.longMessage, longMessage)
        XCTAssertEqual(newMessage.longMessageFormatted, longMessageFormatted)
    }

    func testSendMailOperation() {
        let (queue, message, ids) = createBasicMail()
        let (identity, _, _, _, _) = ids

        XCTAssertNotNil(smtpConnectInfo)

        let encryptionData = EncryptionData(
            imapConnectInfo: imapConnectInfo, smtpConnectInfo: smtpConnectInfo,
            connectionManager: connectionManager,
            messageID: message.objectID, outgoing: true)

        let contact = NSMutableDictionary()
        contact[kPepUsername] = "Unit 001"
        contact[kPepAddress] = "unittest.ios.1@peptest.ch"

        // Build emails
        let numMails = 5
        for i in 1...numMails {
            let fakeMail: NSMutableDictionary = [:]
            fakeMail[kPepFrom] = identity
            fakeMail[kPepOutgoing] = true
            fakeMail[kPepTo] = [contact]
            fakeMail[kPepShortMessage] = "Subject \(i)"
            fakeMail[kPepLongMessage]  = "Body \(i)"
            encryptionData.messagesToSend.append(fakeMail as NSDictionary as! PEPMessage)
        }

        let expMailsSent = expectation(description: "expMailsSent")

        let sendOp = SendMessageOperation.init(encryptionData: encryptionData)
        sendOp.completionBlock = {
            expMailsSent.fulfill()
        }

        queue.addOperation(sendOp)

        waitForExpectations(timeout: TestUtil.waitTime * 2, handler: { error in
            XCTAssertNil(error)
            XCTAssertEqual(sendOp.errors.count, 0)
            XCTAssertEqual(encryptionData.messagesSent.count, numMails)
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

        let color2 = session.outgoingColor(from: myself as NSDictionary as! PEPIdentity,
                                           to: myself as NSDictionary as! PEPIdentity)
        XCTAssertGreaterThanOrEqual(color2.rawValue, PEP_rating_reliable.rawValue)
    }

    func testOutgoingMailColorPerformanceWithMySelf() {
        let session = PEPSession.init()
        let (identity, _, _, _, _) = TestUtil.setupSomeIdentities(session)
        let myself = identity.mutableCopy() as! NSMutableDictionary
        session.mySelf(myself)
        XCTAssertNotNil(myself[kPepFingerprint])

        self.measure {
            for _ in [1...1000] {
                let _ = session.outgoingColor(from: myself as NSDictionary as! PEPIdentity,
                                              to: myself as NSDictionary as! PEPIdentity)
            }
        }
    }

    func testOutgoingMailColorPerformanceWithoutMySelf() {
        let session = PEPSession.init()
        let (identity, _, _, _, _) = TestUtil.setupSomeIdentities(session)
        let myself = identity.mutableCopy() as! NSMutableDictionary

        self.measure {
            for _ in [1...1000] {
                let _ = session.outgoingColor(from: myself as NSDictionary as! PEPIdentity,
                                              to: myself as NSDictionary as! PEPIdentity)
            }
        }
    }

    func testMyselfOperation() {
        XCTAssertNotNil(account.identity)
        XCTAssertNil(account.identity?.fingerPrint)
        let expCompleted = expectation(description: "expCompleted")

        let op = MySelfOperation()
        op.completionBlock = {
            expCompleted.fulfill()
        }

        OperationQueue().addOperation(op)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })

        XCTAssertNotNil(account.identity?.fingerPrint)
    }
}
