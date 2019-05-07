import XCTest

import CoreData

@testable import pEpForiOS
@testable import MessageModel
import PEPObjCAdapterFramework
import PantomimeFramework

class SimpleOperationsTest: CoreDataDrivenTestBase {
    func testComp() {
        guard let f = SyncFoldersFromServerOperation(parentName: #function,
                                                     imapSyncData: imapSyncData)
            else {
                XCTFail()
                return
        }
        XCTAssertTrue(f.comp.contains("SyncFoldersFromServerOperation"))
        XCTAssertTrue(f.comp.contains(#function))
    }

    func testFetchMessagesOperation() {
        XCTAssertNil(CdMessage.all())

        fetchMessages(parentName: #function)

        XCTAssertGreaterThan(
            CdFolder.countBy(predicate: NSPredicate(value: true)), 0)
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
            XCTAssertNotNil(m.sent)
            XCTAssertNotNil(m.received)

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
        TestUtil.checkForExistanceAndUniqueness(uuids: uuids)
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
            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
            imap.localFlags = localFlags
            if let serverFlags = imap.serverFlags {
                localFlags.update(cdImapFlags: serverFlags)
                localFlags.flagSeen = !localFlags.flagSeen
            } else {
                XCTFail()
            }
        }

        Record.saveAndWait()

        let changedMessages = SyncFlagsToServerOperation.messagesToBeSynced(folder: folder,
                                                                            context: moc)
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
            m.refresh(mergeChanges: true, in: moc)
            XCTAssertFalse(m.imap?.localFlags?.flagSeen == flagsSeenBefore[i])
        }
    }

    func testSyncMessagesFailedOperation() {
        testSyncFoldersFromServerOperation()

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

    func testSyncFoldersFromServerOperation() {
        let expFoldersFetched = expectation(description: "expFoldersFetched")

        let opLogin = LoginImapOperation(parentName: #function, imapSyncData: imapSyncData)
        guard let op = SyncFoldersFromServerOperation(parentName: #function,
                                                      imapSyncData: imapSyncData)
            else {
                XCTFail()
                return
        }
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
            CdFolder.countBy(predicate: NSPredicate(value: true)), 1)

        var options: [String: Any] = ["folderTypeRawValue": FolderType.inbox.rawValue,
                                      "account": cdAccount as Any]
        let inboxFolder = CdFolder.first(attributes: options)
        options["folderTypeRawValue"] = FolderType.sent.rawValue
        XCTAssertNotNil(inboxFolder)
        XCTAssertEqual(inboxFolder?.name?.lowercased(),
                       ImapSync.defaultImapInboxName.lowercased())

        let sentFolder = CdFolder.first(attributes: options)
        XCTAssertNotNil(sentFolder)
    }

    func testStorePrefetchedMailOperation() {
        let folder = CWIMAPFolder(name: ImapSync.defaultImapInboxName)

        let _ = CdFolder.insertOrUpdate(
            folderName: folder.name(), folderSeparator: nil, folderType: nil, account: cdAccount)
        Record.saveAndWait()

        let message = CWIMAPMessage()
        message.setFrom(CWInternetAddress(personal: "personal", address: "somemail@test.com"))
        message.setFolder(folder)
        message.setMessageID("001@whatever.test")

        let expStored = expectation(description: "expStored")
        guard let accountId = imapConnectInfo.accountObjectID else {
            XCTFail()
            return
        }
        let storeOp = StorePrefetchedMailOperation(parentName: #function, accountID: accountId,
                                                   message: message,
                                                   messageUpdate: CWMessageUpdate())
        storeOp.completionBlock = {
            storeOp.completionBlock = nil
            expStored.fulfill()
        }
        let backgroundQueue = OperationQueue()
        backgroundQueue.addOperation(storeOp)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(storeOp.hasErrors())
        })

        XCTAssertEqual(CdMessage.all()?.count, 1)
    }

    func testStoreMultipleMails() {
        let folder = CWIMAPFolder(name: ImapSync.defaultImapInboxName)
        let numMails = 10
        var numberOfCallbacksCalled = 0

        let _ = CdFolder.insertOrUpdate(
            folderName: folder.name(), folderSeparator: nil, folderType: nil,account: cdAccount)
        Record.saveAndWait()
        XCTAssertEqual(CdFolder.countBy(predicate: NSPredicate(value: true)), 1)

        let expMailsStored = expectation(description: "expMailsStored")
        let backgroundQueue = OperationQueue()
        for i in 1...numMails {
            let message = CWIMAPMessage()
            message.setFrom(CWInternetAddress(personal: "personal\(i)",
                address: "somemail\(i)@test.com"))
            message.setSubject("Subject \(i)")
            message.setRecipients([CWInternetAddress(personal: "thisIsMe",
                                                     address: "myaddress@test.com", type: .toRecipient)])
            message.setFolder(folder)
            message.setUID(UInt(i))
            message.setMessageID("\(i)@whatever.test")
            guard let accountId = imapConnectInfo.accountObjectID else {
                XCTFail()
                return
            }
            let op = StorePrefetchedMailOperation(parentName: #function,
                                                  accountID: accountId,
                                                  message: message,
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

    /// The test makes no sense for servers supporting Special-Use Mailboxes, as it is not allowed
    /// to delete folder marked as reserved for special-use
    func testCreateRequiredFoldersOperation() {
        let imapLogin = LoginImapOperation(
            parentName: #function, imapSyncData: imapSyncData)

        let expFoldersFetched = expectation(description: "expFoldersFetched")
        guard let syncFoldersOp = SyncFoldersFromServerOperation(parentName: #function,
                                                                 imapSyncData: imapSyncData)
            else {
                XCTFail()
                return
        }
        syncFoldersOp.addDependency(imapLogin)
        syncFoldersOp.completionBlock = {
            syncFoldersOp.completionBlock = nil
            expFoldersFetched.fulfill()
        }

        let backgroundQueue = OperationQueue()
        backgroundQueue.addOperation(imapLogin)
        backgroundQueue.addOperation(syncFoldersOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors())
            XCTAssertFalse(syncFoldersOp.hasErrors())
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

        //dirty workaround for Yahoo account (server with specil-use mailboxes)
        if cdAccount.identity!.address!.contains("yahoo") {
            return
        }
        // Let's delete a special folder, if it exists
        if let spamFolder = CdFolder.by(folderType: .trash, account: cdAccount),
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
            if
                let cdF = CdFolder.by(folderType: ft, account: cdAccount),
                let folderName = cdF.name {
                if let sep = cdF.folderSeparatorAsString(), cdF.parent != nil {
                    XCTAssertTrue(folderName.contains(sep))
                }
            } else {
                XCTFail("expecting folder of type \(ft) with defined name")
            }
        }
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
        // Create mails to send ...
        let sentUUIDs = try! TestUtil.createOutgoingMails(cdAccount: cdAccount,
                                                          testCase: self,
                                                          numberOfMails: 3,
                                                          context: moc).map { $0.uuid! }
        // ... Login ...
        let smtpSendData = SmtpSendData(connectInfo: smtpConnectInfo)
        let errorContainer = ErrorContainer()
        let smtpLogin = LoginSmtpOperation(parentName: #function,
                                           smtpSendData: smtpSendData,
                                           errorContainer: errorContainer)
        smtpLogin.completionBlock = {
            smtpLogin.completionBlock = nil
            XCTAssertNotNil(smtpSendData.smtp)
        }
        // ... and send them.
        let expMailsSent = expectation(description: "expMailsSent")
        let sendOp = EncryptAndSendOperation(
            parentName: #function,
            smtpSendData: smtpSendData, errorContainer: errorContainer)
        XCTAssertNotNil(EncryptAndSendOperation.retrieveNextMessage(context: moc,
                                                                    cdAccount: cdAccount))
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
        // Check sent status of all sent mails
        for sentUuid in sentUUIDs {
            let msgs = CdMessage.search(byUUID: sentUuid, includeFakeMessages: false)
            XCTAssertEqual(msgs.count, 1)
            guard let msg = msgs.first else {
                XCTFail("Missing sent message")
                return
            }
            // Have been moved from outbox to sent
            XCTAssertEqual(msg.parent?.folderType, FolderType.sent)
        }
        smtpSendData.smtp?.close()
    }

    func testAppendSentMailsOperation() {
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()

        let queue = OperationQueue()

        loginIMAP(imapSyncData: imapSyncData, errorContainer: errorContainer, queue: queue)
        fetchFoldersIMAP(imapSyncData: imapSyncData, queue: queue)

        guard let from = cdAccount.identity else {
            XCTFail()
            return
        }

        let to = CdIdentity(context: moc)
        to.userName = "Unit 001"
        to.address = "unittest.ios.1@peptest.ch"

        guard let folder = CdFolder.by(folderType: .sent, account: cdAccount) else {
            XCTFail("No folder")
            return
        }

        // Build emails
        let numMails = 5
        for i in 1...numMails {
            let message = CdMessage(context: moc)
            message.from = from
            message.parent = folder
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.sent = Date()
            message.addToTo(to)
        }
        moc.saveAndLogErrors()

        if let msgs = CdMessage.all() as? [CdMessage] {
            for m in msgs {
                XCTAssertEqual(m.parent?.folderType, FolderType.sent)
                XCTAssertEqual(m.uid, Int32(0))
            }
        } else {
            XCTFail()
        }

        appendMailsIMAP(folder: folder,
                        imapSyncData: imapSyncData,
                        errorContainer: errorContainer,
                        queue: queue)

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
        guard let syncFoldersOp = SyncFoldersFromServerOperation(parentName: #function,
                                                                 imapSyncData: imapSyncData)
            else {
                XCTFail()
                return
        }
        syncFoldersOp.addDependency(imapLogin)
        syncFoldersOp.completionBlock = {
            syncFoldersOp.completionBlock = nil
            expFoldersFetched.fulfill()
        }

        let queue = OperationQueue()
        queue.addOperation(imapLogin)
        queue.addOperation(syncFoldersOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors())
            XCTAssertFalse(syncFoldersOp.hasErrors())
        })

        let from = CdIdentity(context: moc)
        from.userName = cdAccount.identity?.userName ?? "Unit 004"
        from.address = cdAccount.identity?.address ?? "unittest.ios.4@peptest.ch"

        let to = CdIdentity(context: moc)
        to.userName = "Unit 001"
        to.address = "unittest.ios.1@peptest.ch"

        guard let folder = CdFolder.by(folderType: .drafts, account: cdAccount) else {
            XCTFail("No folder")
            return
        }

        // Build emails
        let numMails = 5
        for i in 1...numMails {
            let message = CdMessage(context: moc)
            message.from = from
            message.parent = folder
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.addToTo(to)
        }
        Record.saveAndWait()

        if let msgs = CdMessage.all() as? [CdMessage] {
            for m in msgs {
                XCTAssertEqual(m.parent?.folderType, FolderType.drafts)
                XCTAssertEqual(m.uid, Int32(0))
            }
        } else {
            XCTFail()
        }

        let expDraftsStored = expectation(description: "expDraftsStored")

        let appendOp = AppendMailsOperation(parentName: #function,
                                            folder: folder,
                                            imapSyncData: imapSyncData,
                                            errorContainer: errorContainer)
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
        let (myself, _, _, _, _) = TestUtil.setupSomeIdentities(session)
        try! session.mySelf(myself)
        XCTAssertNotNil(myself.fingerPrint)

        let numRating = try! session.rating(for: myself)
        XCTAssertGreaterThanOrEqual(numRating.pEpRating.rawValue, PEPRating.reliable.rawValue)
    }

    func testOutgoingMailColorPerformanceWithMySelf() {
        let moc = Stack.shared.newPrivateConcurrentContext
        let (myself, _, _, _, _) = TestUtil.setupSomeIdentities(session)
        try! session.mySelf(myself)
        XCTAssertNotNil(myself.fingerPrint)

        guard let id = CdIdentity.from(pEpContact: myself, context: moc) else {
            XCTFail()
            return
        }

        let account = SecretTestData().createWorkingCdAccount(context: moc)
        account.identity = id
        moc.saveAndLogErrors()

        self.measure {
            for _ in [1...1000] {
                let _ = self.session.outgoingMessageRating(from: id, to: [id], cc: [id], bcc: [id])
            }
        }
    }

    func testOutgoingMessageColor() {
        let moc = Stack.shared.newPrivateConcurrentContext
        let account = SecretTestData().createWorkingCdAccount(context: moc)
        moc.saveAndLogErrors()

        guard let identity = account.identity else {
            XCTFail()
            return
        }

        self.measure {
            for _ in [1...1000] {
                let _ = self.session.outgoingMessageRating(from: identity, to: [identity],
                                                           cc: [identity], bcc: [identity])
            }
        }
    }

    func testOutgoingMailColorPerformanceWithoutMySelf() {
        let moc = Stack.shared.newPrivateConcurrentContext
        let (myself, _, _, _, _) = TestUtil.setupSomeIdentities(session)

        guard let id = CdIdentity.from(pEpContact: myself, context: moc) else {
            XCTFail()
            return
        }

        let account = SecretTestData().createWorkingCdAccount(context: moc)
        account.identity = id
        Record.saveAndWait()

        self.measure {
            for _ in [1...1000] {
                let _ = self.session.outgoingMessageRating(from: id, to: [id], cc: [id], bcc: [id])
            }
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
        XCTAssertNotNil(try! theIdent.fingerPrint(session: session))

        let identDict = theIdent.updatedIdentity(session: session)
        XCTAssertNotNil(identDict.fingerPrint)
        XCTAssertNotNil(identDict.userID)
    }

    //fails on first run when the an account was setup on
    func testFixAttachmentsOperation() {
        let moc = Stack.shared.newPrivateConcurrentContext
        let cdFolder = CdFolder(context: moc)
        cdFolder.name = "AttachmentTestFolder"
        cdFolder.folderType = FolderType.inbox
        cdFolder.account = (moc.object(with: cdAccount.objectID) as! CdAccount)

        let cdMsg = CdMessage(context: moc)
        cdMsg.uuid = "2"
        cdMsg.parent = cdFolder

        let cdAttachWithoutSize = CdAttachment(context: moc)
        cdAttachWithoutSize.data = "Some bytes for an attachment".data(using: .utf8)
        cdAttachWithoutSize.message = cdMsg

        moc.saveAndLogErrors()

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

        moc.refreshAllObjects()
        
        guard let allAttachments = CdAttachment.all() as? [CdAttachment] else {
            XCTFail()
            return
        }
        for cdAttach in allAttachments {
            XCTAssertNotNil(cdAttach.data)
        }
    }

    // MARK: - QualifyServerIsLocalOperation

    func testQualifyServerOperation() {
        XCTAssertEqual(isLocalServer(serverName: "localhost"), true)
        XCTAssertEqual(isLocalServer(serverName: "peptest.ch"), false)
    }

    func isLocalServer(serverName: String) -> Bool? {
        let expServerQualified = expectation(description: "expServerQualified")
        let op = QualifyServerIsLocalOperation(serverName: serverName)
        op.completionBlock = {
            expServerQualified.fulfill()
        }
        let queue = OperationQueue()
        queue.addOperation(op)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors())
        })
        return op.isLocal
    }
}
