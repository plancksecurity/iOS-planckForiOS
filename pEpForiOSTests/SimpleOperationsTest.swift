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
            XCTAssertNotNil(m.messageID)
            XCTAssertNotNil(m.uid)
            XCTAssertGreaterThan(m.uid, 0)
            XCTAssertNotNil(m.imap)
            XCTAssertNotNil(m.shortMessage)
            XCTAssertNotNil(m.sent)

            // Transform the message from CdMessage to Message to check conversion
            guard let normalMessage = Message.from(cdMessage: m) else {
                XCTFail()
                return
            }

            XCTAssertEqual(m.from?.address, normalMessage.from?.address)
            XCTAssertNotNil(normalMessage.uuid)
            XCTAssertNotNil(normalMessage.shortMessage)

            guard let uuid = m.uuid else {
                XCTFail()
                continue
            }
            XCTAssertFalse(uuid.contains(localHostname))

            let isValidMessage = m.longMessage != nil || m.longMessageFormatted != nil ||
                m.attachments?.count ?? 0 > 0
            XCTAssertTrue(isValidMessage)

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

        guard let op = SyncMessagesOperation(
            imapSyncData: imapSyncData, folder: folder, firstUID: folder.firstUID(),
            lastUID: folder.lastUID()) else {
                XCTFail()
                return
        }
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

    func testSyncMessagesFailedOperation() {
        testFetchFoldersOperation()

        guard let folder = CdFolder.by(folderType: .inbox, account: account) else {
            XCTFail()
            return
        }

        let expMailsSynced = expectation(description: "expMailsSynced")

        guard let op = SyncMessagesOperation(
            imapSyncData: imapSyncData, folder: folder, firstUID: 10, lastUID: 1) else {
                XCTFail()
                return
        }
        op.completionBlock = {
            expMailsSynced.fulfill()
        }

        op.start()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertTrue(op.hasErrors())
        })
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
                XCTAssertFalse(op.hasErrors())
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
            imapSyncData: imapSyncData, account: account, folderType: .drafts)
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
        let opCreate = CreateFoldersOperation(imapSyncData: imapSyncData, account: account)
        opCreate.completionBlock = {
            expCreated.fulfill()
        }
        let opLogin = LoginImapOperation(imapSyncData: imapSyncData)
        opCreate.addDependency(opLogin)

        let backgroundQueue = OperationQueue()
        backgroundQueue.addOperation(opLogin)
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
            imapSyncData: imapSyncData, account: account)
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
        guard let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folder: inbox) else {
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

        guard let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folder: inbox) else {
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
                imapSyncData: imapSyncData, folder: inbox) else {
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
        let msg = CdMessage.create(messageID: UUID.generate(), uid: 1)
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

    func testEncryptAndSendOperation() {
        let session = PEPSession()
        TestUtil.importKeyByFileName(
            session, fileName: "Unit 1 unittest.ios.1@peptest.ch (0x9CB8DBCC) pub.asc")

        XCTAssertNotNil(smtpConnectInfo)

        let from = CdIdentity.create()
        from.userName = account.identity?.userName ?? "Unit 004"
        from.address = account.identity?.address ?? "unittest.ios.4@peptest.ch"

        let to = CdIdentity.create()
        to.userName = "Unit 001"
        to.address = "unittest.ios.1@peptest.ch"

        let folder = CdFolder.create()
        folder.uuid = UUID.generate()
        folder.name = "Sent"
        folder.folderType = FolderType.sent.rawValue
        folder.account = account

        // Build emails
        let numMails = 5
        for i in 1...numMails {
            let message = CdMessage.create()
            message.from = from
            message.parent = folder
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.sent = Date() as NSDate
            message.addTo(cdIdentity: to)
        }
        Record.saveAndWait()

        if let msgs = CdMessage.all() as? [CdMessage] {
            for m in msgs {
                XCTAssertEqual(m.parent?.folderType, FolderType.sent.rawValue)
                XCTAssertEqual(m.uid, Int32(0))
                XCTAssertEqual(m.sendStatus, Int16(SendStatus.none.rawValue))
            }
        } else {
            XCTFail()
        }

        let expMailsSent = expectation(description: "expMailsSent")

        let smtpSendData = SmtpSendData(connectInfo: smtpConnectInfo)
        let errorContainer = ErrorContainer()

        let smtpLogin = LoginSmtpOperation(
            smtpSendData: smtpSendData, errorContainer: errorContainer)
        smtpLogin.completionBlock = {
            XCTAssertNotNil(smtpSendData.smtp)
        }

        let sendOp = EncryptAndSendOperation(
            smtpSendData: smtpSendData, errorContainer: errorContainer)
        XCTAssertNotNil(sendOp.retrieveNextMessage(context: Record.Context.default))
        sendOp.addDependency(smtpLogin)
        sendOp.completionBlock = {
            expMailsSent.fulfill()
        }

        let queue = OperationQueue()
        queue.addOperation(smtpLogin)
        queue.addOperation(sendOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(sendOp.hasErrors())
        })

        if let msgs = CdMessage.all() as? [CdMessage] {
            for m in msgs {
                XCTAssertEqual(m.sendStatus, Int16(SendStatus.smtpDone.rawValue))
            }
        } else {
            XCTFail()
        }
    }

    func testAppendSentMailsOperation() {
        XCTAssertNotNil(smtpConnectInfo)

        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()

        let imapLogin = LoginImapOperation(
            imapSyncData: imapSyncData, errorContainer: errorContainer)
        imapLogin.completionBlock = {
            XCTAssertNotNil(imapSyncData.sync)
        }

        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let fetchFoldersOp = FetchFoldersOperation(imapSyncData: imapSyncData)
        fetchFoldersOp.addDependency(imapLogin)
        fetchFoldersOp.completionBlock = {
            expFoldersFetched.fulfill()
        }

        let queue = OperationQueue()
        queue.addOperation(imapLogin)
        queue.addOperation(fetchFoldersOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors())
            XCTAssertFalse(fetchFoldersOp.hasErrors())
        })

        let from = CdIdentity.create()
        from.userName = account.identity?.userName ?? "Unit 004"
        from.address = account.identity?.address ?? "unittest.ios.4@peptest.ch"

        let to = CdIdentity.create()
        to.userName = "Unit 001"
        to.address = "unittest.ios.1@peptest.ch"

        let folder = CdFolder.by(folderType: .sent, account: account)
        XCTAssertNotNil(folder)

        // Build emails
        let numMails = 5
        for i in 1...numMails {
            let message = CdMessage.create()
            message.from = from
            message.parent = folder
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.sendStatus = Int16(SendStatus.smtpDone.rawValue)
            message.addTo(cdIdentity: to)
        }
        Record.saveAndWait()

        if let msgs = CdMessage.all() as? [CdMessage] {
            for m in msgs {
                XCTAssertEqual(m.parent?.folderType, FolderType.sent.rawValue)
                XCTAssertEqual(m.uid, Int32(0))
                XCTAssertEqual(m.sendStatus, Int16(SendStatus.smtpDone.rawValue))
            }
        } else {
            XCTFail()
        }

        let expSentAppended = expectation(description: "expSentAppended")

        let appendOp = AppendMailsOperation(
            imapSyncData: imapSyncData, errorContainer: errorContainer)
        appendOp.completionBlock = {
            expSentAppended.fulfill()
        }

        queue.addOperation(appendOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(appendOp.hasErrors())
        })

        XCTAssertEqual((CdMessage.all() ?? []).count, 0)
    }

    func testAppendDraftMailsOperation() {
        XCTAssertNotNil(smtpConnectInfo)

        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()

        let imapLogin = LoginImapOperation(
            imapSyncData: imapSyncData, errorContainer: errorContainer)
        imapLogin.completionBlock = {
            XCTAssertNotNil(imapSyncData.sync)
        }

        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let fetchFoldersOp = FetchFoldersOperation(imapSyncData: imapSyncData)
        fetchFoldersOp.addDependency(imapLogin)
        fetchFoldersOp.completionBlock = {
            expFoldersFetched.fulfill()
        }

        let queue = OperationQueue()
        queue.addOperation(imapLogin)
        queue.addOperation(fetchFoldersOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors())
            XCTAssertFalse(fetchFoldersOp.hasErrors())
        })

        let from = CdIdentity.create()
        from.userName = account.identity?.userName ?? "Unit 004"
        from.address = account.identity?.address ?? "unittest.ios.4@peptest.ch"

        let to = CdIdentity.create()
        to.userName = "Unit 001"
        to.address = "unittest.ios.1@peptest.ch"

        let folder = CdFolder.by(folderType: .drafts, account: account)
        XCTAssertNotNil(folder)

        // Build emails
        let numMails = 5
        for i in 1...numMails {
            let message = CdMessage.create()
            message.from = from
            message.parent = folder
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.sendStatus = Int16(SendStatus.none.rawValue)
            message.addTo(cdIdentity: to)
        }
        Record.saveAndWait()

        if let msgs = CdMessage.all() as? [CdMessage] {
            for m in msgs {
                XCTAssertEqual(m.parent?.folderType, FolderType.drafts.rawValue)
                XCTAssertEqual(m.uid, Int32(0))
                XCTAssertEqual(m.sendStatus, Int16(SendStatus.none.rawValue))
            }
        } else {
            XCTFail()
        }

        let expDraftsStored = expectation(description: "expDraftsStored")

        let appendOp = AppendDraftMailsOperation(
            imapSyncData: imapSyncData, errorContainer: errorContainer)
        appendOp.completionBlock = {
            expDraftsStored.fulfill()
        }

        queue.addOperation(appendOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(appendOp.hasErrors())
        })
        
        XCTAssertEqual((CdMessage.all() ?? []).count, 0)
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
        let identity = account.identity?.identity()
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

        XCTAssertNotNil(identity?.fingerPrint())
    }
}
