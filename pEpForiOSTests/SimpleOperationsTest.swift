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

class SimpleOperationsTest: OperationTestBase {

    func testComp() {
        let f = FetchFoldersOperation(parentName: #function, imapSyncData: imapSyncData)
        XCTAssertTrue(f.comp.contains("FetchFoldersOperation"))
        XCTAssertTrue(f.comp.contains(#function))
    }

    func testFetchMessagesOperation() {
        XCTAssertNil(CdMessage.all())

        fetchMessages(parentName: #function)

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
        var uuids = [MessageID]()
        for m in allMessages {
            if let uuid = m.messageID {
                uuids.append(uuid)
            } else {
                XCTFail()
            }

            XCTAssertNotNil(m.uid)
            XCTAssertGreaterThan(m.uid, 0)
            XCTAssertNotNil(m.imap)
            XCTAssertNotNil(m.shortMessage)
            if m.sent == nil {
                Log.warn(component: #function, content: "nil sent \(String(describing: m.shortMessage)) \(String(describing: m.uuid))")
            }
            XCTAssertNotNil(m.sent)
            XCTAssertNotNil(m.received)

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

            XCTAssertTrue(m.isValidMessage())

            guard let folder = m.parent else {
                XCTFail()
                break
            }
            XCTAssertEqual(folder.name?.lowercased(), ImapSync.defaultImapInboxName.lowercased())
            guard let messages = CdMessage.all(
                attributes: ["uid": m.uid, "parent": folder]) as? [CdMessage] else {
                    XCTFail()
                    break
            }
            XCTAssertEqual(messages.count, 1)

            XCTAssertNotNil(m.imap)
        }
        TestUtil.checkForUniqueness(uuids: uuids)
    }

    /**
     Currently doesn't do a real test, since what comes from the server will not overwrite
     local flags, to avoid getting rid of user-initiated changes.
     */
    func testSyncMessagesOperation() {
        fetchMessages(parentName: #function)

        guard let folder = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let allMessages = CdMessage.all() as? [CdMessage] else {
            XCTFail()
            return
        }

        let flagsSeenBefore = allMessages.map { $0.imap?.serverFlags?.flagSeen }
        // Change all flags locally
        for m in allMessages {
            guard let imap = m.imap else {
                XCTFail()
                continue
            }
            let localFlags = imap.localFlags ?? CdImapFlags.create()
            imap.localFlags = localFlags
            if let serverFlags = imap.serverFlags {
                localFlags.update(cdImapFlags: serverFlags)
                localFlags.flagSeen = !localFlags.flagSeen
            } else {
                XCTFail()
            }
        }

        Record.saveAndWait()

        let changedMessages = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: folder, context: Record.Context.default)
        XCTAssertEqual(changedMessages.count, allMessages.count)

        let expMailsSynced = expectation(description: "expMailsSynced")

        guard let op = SyncMessagesOperation(
            parentName: #function,
            imapSyncData: imapSyncData, folder: folder) else {
                XCTFail()
                return
        }
        op.completionBlock = {
            op.completionBlock = nil
            expMailsSynced.fulfill()
        }

        op.start()
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })

        // Since the server flags have not changed, we still know that we have local changes
        // that should not get overwritten by the server.
        // Hence, all messages are still the same.
        for (i, m) in allMessages.enumerated() {
            m.refresh(mergeChanges: true, in: Record.Context.default)
            XCTAssertFalse(m.imap?.localFlags?.flagSeen == flagsSeenBefore[i])
        }
    }

    func testSyncMessagesFailedOperation() {
        testFetchFoldersOperation()

        guard
            let folder = CdFolder.by(folderType: .inbox, account: cdAccount),
            let folderName = folder.name else {
                XCTFail()
                return
        }

        let expMailsSynced = expectation(description: "expMailsSynced")

        let op = SyncMessagesOperation(
            parentName: #function,
            imapSyncData: imapSyncData, folderName: folderName, firstUID: 10, lastUID: 5)
        op.completionBlock = {
            op.completionBlock = nil
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

        let opLogin = LoginImapOperation(parentName: #function, imapSyncData: imapSyncData)
        let op = FetchFoldersOperation(parentName: #function, imapSyncData: imapSyncData)
        op.completionBlock = {
            op.completionBlock = nil
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
                                      "account": cdAccount]
        let inboxFolder = CdFolder.first(attributes: options)
        options["folderType"] = FolderType.sent.rawValue
        XCTAssertNotNil(inboxFolder)
        XCTAssertEqual(inboxFolder?.name?.lowercased(),
                       ImapSync.defaultImapInboxName.lowercased())

        let sentFolder = CdFolder.first(attributes: options)
        XCTAssertNotNil(sentFolder)
    }

    func testStorePrefetchedMailOperation() {
        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)

        let _ = CdFolder.insertOrUpdate(
            folderName: folder.name(), folderSeparator: nil, folderType: nil, account: cdAccount) //BUFF:
        Record.saveAndWait()

        let message = CWIMAPMessage.init()
        message.setFrom(CWInternetAddress.init(personal: "personal", address: "somemail@test.com"))
        message.setFolder(folder)
        message.setMessageID("001@whatever.test")

        let expStored = expectation(description: "expStored")
        let storeOp = StorePrefetchedMailOperation(
            parentName: #function,
            accountID: imapConnectInfo.accountObjectID, message: message,
            messageUpdate: CWMessageUpdate())
        storeOp.completionBlock = {
            storeOp.completionBlock = nil
            expStored.fulfill()
        }
        let backgroundQueue = OperationQueue.init()
        backgroundQueue.addOperation(storeOp)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(storeOp.hasErrors())
        })

        XCTAssertEqual(CdMessage.all()?.count, 1)
    }

    func testStoreMultipleMails() {
        let folder = CWIMAPFolder.init(name: ImapSync.defaultImapInboxName)
        let numMails = 10
        var numberOfCallbacksCalled = 0

        let _ = CdFolder.insertOrUpdate(
            folderName: folder.name(), folderSeparator: nil, folderType: nil,account: cdAccount) //BUFF:
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
            let op = StorePrefetchedMailOperation(
                parentName: #function,
                accountID: imapConnectInfo.accountObjectID, message: message,
                messageUpdate: CWMessageUpdate())
            op.completionBlock = {
                op.completionBlock = nil
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

    func testCreateLocalRequiredFoldersOperation() {
        let expFoldersStored = expectation(description: "expFoldersStored")
        let op = CreateLocalRequiredFoldersOperation(
            parentName: #function, account: cdAccount)
        let queue = OperationQueue()
        op.completionBlock = {
            op.completionBlock = nil
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
                                FolderType.localOutbox.rawValue, self.cdAccount)
            let outbox = CdFolder.first(predicate: p)
            XCTAssertNotNil(outbox, "Expected outbox to exist")
        })
    }

    func testCreateFolders() {
        let backgroundQueue = OperationQueue.init()

        let opLogin = LoginImapOperation(
            parentName: #function, imapSyncData: imapSyncData)

        // Fetch folders to get the folder separator
        let opFetchFolders = FetchFoldersOperation(
            parentName: #function, imapSyncData: imapSyncData)
        opFetchFolders.addDependency(opLogin)

        let expCreated = expectation(description: "expCreated")
        let opCreate = CheckAndCreateFolderOfTypeOperation(
            parentName: #function,
            imapSyncData: imapSyncData, account: cdAccount, folderType: .drafts)
        opCreate.addDependency(opFetchFolders)
        opCreate.completionBlock = {
            opCreate.completionBlock = nil
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

        XCTAssertNotNil(CdFolder.by(folderType: .drafts, account: cdAccount))
    }

    func testCreateDeleteFolderOperation() {
        let uuid1 = MessageID.generate()
        let folder1 = CdFolder.create()
        folder1.account = cdAccount
        folder1.uuid = uuid1
        folder1.name = "Inbox.Folder1 \(uuid1)"

        let uuid2 = MessageID.generate()
        let folder2 = CdFolder.create()
        folder2.account = cdAccount
        folder2.uuid = uuid1
        folder2.name = "Inbox.Folder2 \(uuid2)"

        Record.saveAndWait()

        let expCreated = expectation(description: "expCreated")
        let opCreate = CreateFoldersOperation(
            parentName: #function, imapSyncData: imapSyncData, account: cdAccount)
        opCreate.completionBlock = {
            opCreate.completionBlock = nil
            expCreated.fulfill()
        }
        let opLogin = LoginImapOperation(
            parentName: #function, imapSyncData: imapSyncData)
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
            parentName: #function,
            imapSyncData: imapSyncData, account: cdAccount)
        opDelete.completionBlock = {
            opDelete.completionBlock = nil
            expDeleted.fulfill()
        }

        backgroundQueue.addOperation(opDelete)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opDelete.hasErrors())
        })

        XCTAssertNil(CdFolder.by(folderType: .drafts, account: cdAccount))

        // Recreate drafts folder
        testCreateFolders()
        XCTAssertNotNil(CdFolder.by(folderType: .drafts, account: cdAccount))
    }

    func testCreateRequiredFoldersOperation() {
        let imapLogin = LoginImapOperation(
            parentName: #function, imapSyncData: imapSyncData)

        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let fetchFoldersOp = FetchFoldersOperation(
            parentName: #function, imapSyncData: imapSyncData)
        fetchFoldersOp.addDependency(imapLogin)
        fetchFoldersOp.completionBlock = {
            fetchFoldersOp.completionBlock = nil
            expFoldersFetched.fulfill()
        }

        let backgroundQueue = OperationQueue()
        backgroundQueue.addOperation(imapLogin)
        backgroundQueue.addOperation(fetchFoldersOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors())
            XCTAssertFalse(fetchFoldersOp.hasErrors())
        })

        let expCreated1 = expectation(description: "expCreated")
        let opCreate1 = CreateRequiredFoldersOperation(
            parentName: #function, imapSyncData: imapSyncData)
        opCreate1.completionBlock = {
            opCreate1.completionBlock = nil
            expCreated1.fulfill()
        }
        backgroundQueue.addOperation(opCreate1)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opCreate1.hasErrors())
        })

        // Let's delete a special folder, if it exists
        if let spamFolder = CdFolder.by(folderType: .spam, account: cdAccount),
            let fn = spamFolder.name {
            let expDeleted = expectation(description: "expFolderDeleted")
            let opDelete = DeleteFolderOperation(
                parentName: #function,
                imapSyncData: imapSyncData, account: cdAccount, folderName: fn)
            opDelete.completionBlock = {
                opDelete.completionBlock = nil
                expDeleted.fulfill()
            }
            backgroundQueue.addOperation(opDelete)
            waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
                XCTAssertNil(error)
                XCTAssertFalse(opDelete.hasErrors())
            })
            spamFolder.delete()
            Record.saveAndWait()
        } else {
            XCTFail()
        }

        let expCreated2 = expectation(description: "expCreated")
        let opCreate2 = CreateRequiredFoldersOperation(
            parentName: #function, imapSyncData: imapSyncData)
        opCreate2.completionBlock = {
            opCreate2.completionBlock = nil
            expCreated2.fulfill()
        }
        backgroundQueue.addOperation(opCreate2)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opCreate2.hasErrors())
        })
        XCTAssertGreaterThanOrEqual(opCreate2.numberOfFoldersCreated, 1)

        for ft in FolderType.requiredTypes {
            XCTAssertNotNil(CdFolder.by(folderType: ft, account: cdAccount))
        }
    }

    func insertNewMessageForSending(account: CdAccount) -> CdMessage {
        let msg = CdMessage.create(messageID: MessageID.generate(), uid: 1)
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
            let opCreateRequiredFolders = CreateLocalRequiredFoldersOperation(
                parentName: #function, account: cdAccount)
            let expFoldersStored = expectation(description: "expFoldersStored")
            opCreateRequiredFolders.completionBlock = {
                opCreateRequiredFolders.completionBlock = nil
                expFoldersStored.fulfill()
            }

            let queue = OperationQueue.init()
            queue.addOperation(opCreateRequiredFolders)
            waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
                XCTAssertNil(error)
            })

            let message = insertNewMessageForSending(account: cdAccount)

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
                print("\(String(describing: acc.identity?.address)) \(String(describing: acc.identity?.userName))")
            }
        }
    }

    // MARK: - EncryptAndSendOperation

    func testEncryptAndSendOperation() {
        let _ = TestUtil.createOutgoingMails(cdAccount: cdAccount, testCase: self, numberOfMails: 3)

        let expMailsSent = expectation(description: "expMailsSent")

        let smtpSendData = SmtpSendData(connectInfo: smtpConnectInfo)
        let errorContainer = ErrorContainer()

        let smtpLogin = LoginSmtpOperation(
            parentName: #function,
            smtpSendData: smtpSendData, errorContainer: errorContainer)
        smtpLogin.completionBlock = {
            smtpLogin.completionBlock = nil
            XCTAssertNotNil(smtpSendData.smtp)
        }

        let sendOp = EncryptAndSendOperation(
            parentName: #function,
            smtpSendData: smtpSendData, errorContainer: errorContainer)
        XCTAssertNotNil(EncryptAndSendOperation.retrieveNextMessage(
            context: Record.Context.default, cdAccount: cdAccount))
        sendOp.addDependency(smtpLogin)
        sendOp.completionBlock = {
            sendOp.completionBlock = nil
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

        smtpSendData.smtp?.close()
    }

    func testAppendSentMailsOperation() {
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()

        let imapLogin = LoginImapOperation(
            parentName: #function,
            errorContainer: errorContainer, imapSyncData: imapSyncData)
        imapLogin.completionBlock = {
            imapLogin.completionBlock = nil
            XCTAssertNotNil(imapSyncData.sync)
        }

        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let fetchFoldersOp = FetchFoldersOperation(
            parentName: #function, imapSyncData: imapSyncData)
        fetchFoldersOp.addDependency(imapLogin)
        fetchFoldersOp.completionBlock = {
            fetchFoldersOp.completionBlock = nil
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
        from.userName = cdAccount.identity?.userName ?? "Unit 004"
        from.address = cdAccount.identity?.address ?? "unittest.ios.4@peptest.ch"

        let to = CdIdentity.create()
        to.userName = "Unit 001"
        to.address = "unittest.ios.1@peptest.ch"

        let folder = CdFolder.by(folderType: .sent, account: cdAccount)
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
            message.sent = Date() as NSDate
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
            parentName: #function,
            imapSyncData: imapSyncData, errorContainer: errorContainer)
        appendOp.completionBlock = {
            appendOp.completionBlock = nil
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
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()

        let imapLogin = LoginImapOperation(
            parentName: #function,
            errorContainer: errorContainer, imapSyncData: imapSyncData)
        imapLogin.completionBlock = {
            imapLogin.completionBlock = nil
            XCTAssertNotNil(imapSyncData.sync)
        }

        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let fetchFoldersOp = FetchFoldersOperation(
            parentName: #function, imapSyncData: imapSyncData)
        fetchFoldersOp.addDependency(imapLogin)
        fetchFoldersOp.completionBlock = {
            fetchFoldersOp.completionBlock = nil
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
        from.userName = cdAccount.identity?.userName ?? "Unit 004"
        from.address = cdAccount.identity?.address ?? "unittest.ios.4@peptest.ch"

        let to = CdIdentity.create()
        to.userName = "Unit 001"
        to.address = "unittest.ios.1@peptest.ch"

        let folder = CdFolder.by(folderType: .drafts, account: cdAccount)
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
            parentName: #function,
            imapSyncData: imapSyncData, errorContainer: errorContainer)
        appendOp.completionBlock = {
            appendOp.completionBlock = nil
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

        let color2 = session.identityRating(myself as NSDictionary as! PEPIdentity)
        XCTAssertGreaterThanOrEqual(color2.rawValue, PEP_rating_reliable.rawValue)
    }

    func testOutgoingMailColorPerformanceWithMySelf() {
        let session = PEPSession.init()
        let (identity, _, _, _, _) = TestUtil.setupSomeIdentities(session)
        let myself = identity.mutableCopy() as! NSMutableDictionary
        session.mySelf(myself)
        XCTAssertNotNil(myself[kPepFingerprint])

        if let theID = identity as NSDictionary as? PEPIdentity,
            let id = Identity.from(pEpIdentity: theID) {
            self.measure {
                for _ in [1...1000] {
                    let _ = PEPUtil.outgoingMessageColor(from: id, to: [id],
                                                         cc: [id], bcc: [id],
                                                         session: session)
                }
            }
        } else {
            XCTFail()
        }
    }

    func testOutgoingMessageColor() {
        let session = PEPSession.init()
        let identity = TestData().createWorkingAccount().user
        self.measure {
            for _ in [1...1000] {
                let _ = PEPUtil.outgoingMessageColor(from: identity, to: [identity],
                                                     cc: [identity], bcc: [identity],
                                                     session: session)
            }
        }
    }

    func testOutgoingMailColorPerformanceWithoutMySelf() {
        let session = PEPSession.init()
        let (identity, _, _, _, _) = TestUtil.setupSomeIdentities(session)

        if let theID = identity as NSDictionary as? PEPIdentity,
            let id = Identity.from(pEpIdentity: theID) {
            self.measure {
                for _ in [1...1000] {
                    let _ = PEPUtil.outgoingMessageColor(from: id, to: [id],
                                                         cc: [id], bcc: [id],
                                                         session: session)
                }
            }
        } else {
            XCTFail()
        }
    }

    func testMyselfOperation() {
        XCTAssertNotNil(cdAccount.identity)
        let identity = cdAccount.identity?.identity()
        let expCompleted = expectation(description: "expCompleted")

        let op = MySelfOperation(parentName: #function)
        op.completionBlock = {
            op.completionBlock = nil
            expCompleted.fulfill()
        }

        OperationQueue().addOperation(op)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })

        guard let theIdent = identity else {
            XCTFail()
            return
        }
        XCTAssertNotNil(theIdent.fingerPrint())

        let session = PEPSession.init()
        let identDict = theIdent.updatedIdentityDictionary(session: session)
        XCTAssertNotNil(identDict[kPepFingerprint])
        XCTAssertNotNil(identDict[kPepUserID])
    }

    func testTrashMessages() {
        let errorContainer = ErrorContainer()

        let imapLogin = LoginImapOperation(
            parentName: #function,
            errorContainer: errorContainer, imapSyncData: imapSyncData)
        imapLogin.completionBlock = {
            imapLogin.completionBlock = nil
            XCTAssertNotNil(self.imapSyncData.sync)
        }

        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let fetchFoldersOp = FetchFoldersOperation(
            parentName: #function, imapSyncData: imapSyncData)
        fetchFoldersOp.addDependency(imapLogin)
        fetchFoldersOp.completionBlock = {
            fetchFoldersOp.completionBlock = nil
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
        from.userName = cdAccount.identity?.userName ?? "Unit 004"
        from.address = cdAccount.identity?.address ?? "unittest.ios.4@peptest.ch"

        let to = CdIdentity.create()
        to.userName = "Unit 001"
        to.address = "unittest.ios.1@peptest.ch"

        guard let inboxFolder = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }
        guard let draftsFolder = CdFolder.by(folderType: .drafts, account: cdAccount) else {
            XCTFail()
            return
        }
        guard let trashFolder = CdFolder.by(folderType: .trash, account: cdAccount) else {
            XCTFail()
            return
        }

        // Build emails
        var originalMessages = [CdMessage]()
        let numMails = 3
        for i in 1...numMails {
            let message = CdMessage.create()
            message.from = from
            if i == 1 {
                message.parent = draftsFolder
            } else {
                message.parent = inboxFolder
            }
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.sendStatus = Int16(SendStatus.none.rawValue)
            message.addTo(cdIdentity: to)
            let imapFields = CdImapFields.create()
            let imapFlags = CdImapFlags.create()
            imapFields.localFlags = imapFlags
            imapFlags.flagDeleted = true
            imapFields.trashedStatus = TrashedStatus.shouldBeTrashed.rawValue
            message.imap = imapFields
            originalMessages.append(message)
        }
        Record.saveAndWait()

        let foldersToTrash = TrashMailsOperation.foldersWithTrashedMessages(
            context: Record.Context.default)
        XCTAssertEqual(foldersToTrash.count, 2)
        if inboxFolder.name ?? "" < draftsFolder.name ?? "" {
            XCTAssertEqual(foldersToTrash[safe: 0], inboxFolder)
            XCTAssertEqual(foldersToTrash[safe: 1], draftsFolder)
        } else {
            XCTAssertEqual(foldersToTrash[safe: 1], inboxFolder)
            XCTAssertEqual(foldersToTrash[safe: 0], draftsFolder)
        }

        if let msgs = CdMessage.all() as? [CdMessage] {
            for m in msgs {
                XCTAssertNotNil(m.messageID)
                XCTAssertTrue(m.parent?.folderType == FolderType.inbox.rawValue ||
                    m.parent?.folderType == FolderType.drafts.rawValue)
                XCTAssertEqual(m.uid, Int32(0))
                XCTAssertEqual(m.sendStatus, Int16(SendStatus.none.rawValue))
            }
        } else {
            XCTFail()
        }

        let expTrashed = expectation(description: "expTrashed")

        let trashMailsOp1 = TrashMailsOperation(
            parentName: #function,
            imapSyncData: imapSyncData, errorContainer: errorContainer, folder: inboxFolder)
        let trashMailsOp2 = TrashMailsOperation(
            parentName: #function,
            imapSyncData: imapSyncData, errorContainer: errorContainer, folder: draftsFolder)
        trashMailsOp2.addDependency(trashMailsOp1)
        trashMailsOp2.completionBlock = {
            trashMailsOp2.completionBlock = nil
            expTrashed.fulfill()
        }

        queue.addOperation(trashMailsOp1)
        queue.addOperation(trashMailsOp2)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(trashMailsOp2.hasErrors())
        })

        Record.Context.default.refreshAllObjects()
        XCTAssertEqual(trashFolder.messages?.count ?? 0, 0)

        let expTrashFetched = expectation(description: "expTrashFetched")

        let fetchTrashOp = FetchMessagesOperation(
            parentName: #function, errorContainer: errorContainer, imapSyncData: imapSyncData,
            folderName: trashFolder.name ?? "", messageFetchedBlock: nil)
        fetchTrashOp.completionBlock = {
            fetchTrashOp.completionBlock = nil
            expTrashFetched.fulfill()
        }

        queue.addOperation(fetchTrashOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(trashMailsOp2.hasErrors())
        })

        for m in originalMessages {
            guard let mID = m.uuid else {
                XCTFail()
                continue
            }
            let uuidP = NSPredicate(format: "uuid = %@", mID)
            guard let cdMessages = CdMessage.all(predicate: uuidP) else {
                XCTFail()
                continue
            }
            XCTAssertEqual(cdMessages.count, 2)

            guard let folder = m.parent else {
                XCTFail()
                continue
            }
            XCTAssertTrue(folder.folderType == FolderType.inbox.rawValue ||
                folder.folderType == FolderType.drafts.rawValue)
            guard let imap = m.imap else {
                XCTFail()
                continue
            }
            XCTAssertTrue(imap.localFlags?.flagDeleted ?? false)
            XCTAssertEqual(imap.trashedStatus, TrashedStatus.trashed.rawValue)
            // Make sure the email now exists in the trash folder as well
            let trashedP = NSPredicate(format: "parent = %@", trashFolder)
            let trashedP1 = NSCompoundPredicate(andPredicateWithSubpredicates: [uuidP, trashedP])
            let trashedCdMessage = CdMessage.first(predicate: trashedP1)
            XCTAssertNotNil(trashedCdMessage)
        }
    }
    
    //fails on first run when the an account was setup on
    func testFixAttachmentsOperation() {
        let cdFolder = CdFolder.create()
        cdFolder.name = "AttachmentTestFolder"
        cdFolder.uuid = "1"
        cdFolder.folderType = FolderType.inbox.rawValue
        cdFolder.account = cdAccount
        
        let cdMsg = CdMessage.create(messageID: "2", uid: 1, parent: cdFolder)
        
        let cdAttachWithoutSize = CdAttachment.create()
        cdAttachWithoutSize.data = "Some bytes for an attachment".data(using: .utf8) as NSData?
        cdAttachWithoutSize.message = cdMsg
        cdAttachWithoutSize.length = 0
        
        Record.saveAndWait()
        
        let expAttachmentsFixed = expectation(description: "expAttachmentsFixed")
        let fixAttachmentsOp = FixAttachmentsOperation(parentName: #function)
        fixAttachmentsOp.completionBlock = {
            fixAttachmentsOp.completionBlock = nil
            expAttachmentsFixed.fulfill()
        }
        let queue = OperationQueue()
        queue.addOperation(fixAttachmentsOp)
        
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(fixAttachmentsOp.hasErrors())
        })
        
        Record.Context.default.refreshAllObjects()
        
        guard let allAttachments = CdAttachment.all() as? [CdAttachment] else {
            XCTFail()
            return
        }
        for cdAttach in allAttachments {
            XCTAssertNotNil(cdAttach.data)
            XCTAssertNotNil(cdAttach.length)
            XCTAssertGreaterThan(cdAttach.length, 0)
        }
    }
}
