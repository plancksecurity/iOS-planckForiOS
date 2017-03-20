///
//  SimpleOperationsTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 03/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData
import Photos

import pEpForiOS
import MessageModel

class SimpleOperationsTest: XCTestCase {
    var connectionManager: ConnectionManager!
    var cdAccount: CdAccount!
    var persistentSetup: PersistentSetup!
    var imapConnectInfo: EmailConnectInfo!
    var smtpConnectInfo: EmailConnectInfo!
    var imapSyncData: ImapSyncData!

    override func setUp() {
        super.setUp()
        /*
         The idea is to delete all messages on server befor every test.
         My time went out, I had to leave, so I left it in non-working state.

         What I (want to) do in flagAllMessagesDeletedOnServer() is to:
         - get all mails from all folders from server
         - flag all mails deleted
         - sync flags to server for all mails from all folders
         - delete local store incl. sqlite file(s)

         Even I assert they are flagged deleted afterwards, all mails are still shown in Thunderbird.
         */
        //flagAllMessagesDeletedOnServer()
        setAllProperties()
    }

    override func tearDown() {
        setAllPropertiesNil()
        super.tearDown()
    }

    func testComp() {
        let f = FetchFoldersOperation(imapSyncData: imapSyncData)
        XCTAssertEqual(f.comp, "FetchFoldersOperation")
    }

    func testFetchMessagesOperation() {
        XCTAssertNil(CdMessage.all())

        fetchMessages()

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
                Log.warn(component: #function, content: "nil sent \(m.shortMessage) \(m.uuid)")
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

            let isValidMessage = m.longMessage != nil || m.longMessageFormatted != nil ||
                m.attachments?.count ?? 0 > 0
            XCTAssertTrue(isValidMessage)

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
        fetchMessages()

        guard let folder = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let allMessages = CdMessage.all() as? [CdMessage] else {
            XCTFail()
            return
        }

        let flagsSeenBefore = allMessages.map { $0.imap?.flagSeen }
        // Change all flags locally
        for m in allMessages {
            guard let imap = m.imap else {
                XCTFail()
                continue
            }
            imap.flagSeen = !imap.flagSeen
        }

        Record.saveAndWait()

        let changedMessages = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: folder, context: Record.Context.default) ?? []
        XCTAssertEqual(changedMessages.count, allMessages.count)

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

        // Since the server flags have not changed, we still know that we have local changes
        // that should not get overwritten by the server.
        // Hence, all messages are still the same.
        for (i, m) in allMessages.enumerated() {
            m.refresh(mergeChanges: true, in: Record.Context.default)
            XCTAssertFalse(m.imap?.flagSeen == flagsSeenBefore[i])
        }
    }

    func testSyncMessagesFailedOperation() {
        testFetchFoldersOperation()

        guard let folder = CdFolder.by(folderType: .inbox, account: cdAccount) else {
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
            folderName: folder.name(), folderSeparator: nil, account: cdAccount)
        Record.saveAndWait()

        let message = CWIMAPMessage.init()
        message.setFrom(CWInternetAddress.init(personal: "personal", address: "somemail@test.com"))
        message.setFolder(folder)
        message.setMessageID("001@whatever.test")

        let expStored = expectation(description: "expStored")
        let op = StorePrefetchedMailOperation(
            accountID: imapConnectInfo.accountObjectID, message: message,
            messageUpdate: CWMessageUpdate())
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
            folderName: folder.name(), folderSeparator: nil, account: cdAccount)
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
                accountID: imapConnectInfo.accountObjectID, message: message,
                messageUpdate: CWMessageUpdate())
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
        let op = CreateLocalSpecialFoldersOperation(account: cdAccount)
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
                                FolderType.localOutbox.rawValue, self.cdAccount)
            let outbox = CdFolder.first(predicate: p)
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
            imapSyncData: imapSyncData, account: cdAccount, folderType: .drafts)
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
        let opCreate = CreateFoldersOperation(imapSyncData: imapSyncData, account: cdAccount)
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
            imapSyncData: imapSyncData, account: cdAccount)
        opDelete.completionBlock = {
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

    func testCreateSpecialFoldersOperation() {
        let imapLogin = LoginImapOperation(imapSyncData: imapSyncData)

        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let fetchFoldersOp = FetchFoldersOperation(imapSyncData: imapSyncData)
        fetchFoldersOp.addDependency(imapLogin)
        fetchFoldersOp.completionBlock = {
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
        let opCreate1 = CreateSpecialFoldersOperation(imapSyncData: imapSyncData)
        opCreate1.completionBlock = {
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
                imapSyncData: imapSyncData, account: cdAccount, folderName: fn)
            opDelete.completionBlock = {
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
        let opCreate2 = CreateSpecialFoldersOperation(imapSyncData: imapSyncData)
        opCreate2.completionBlock = {
            expCreated2.fulfill()
        }
        backgroundQueue.addOperation(opCreate2)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opCreate2.hasErrors())
        })
        XCTAssertGreaterThanOrEqual(opCreate2.numberOfFoldersCreated, 1)

        for ft in FolderType.neededFolderTypes {
            XCTAssertNotNil(CdFolder.by(folderType: ft, account: cdAccount))
        }
    }

    //MARK: - SyncFlagsToServerOperation

    func testSyncFlagsToServerOperationEmpty() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
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
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            imap.flagFlagged = !imap.flagFlagged
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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0)
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count)
    }

    func testSyncFlagsToServerOperationAddFlags_changeAllFlags() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)]) as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // all flags set locally ...
            imap.flagAnswered = true
            imap.flagDraft = true
            imap.flagFlagged = true
            // the client must never change flagRecent according to RFC, so we set it in state of flagsServer
            imap.flagRecent = false
            imap.flagSeen = true
            imap.flagDeleted = true
            // ...but no flags are set on server, so all flags have to be added
            imap.flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0)
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count)
    }

    func testSyncFlagsToServerOperationAddFlags_allFlagsAlreadySetOnServer() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // all flags set locally ...
            imap.flagAnswered = true
            imap.flagDraft = true
            imap.flagFlagged = true
            // the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer
            imap.flagRecent = true
            imap.flagSeen = true
            imap.flagDeleted = true
            // ...and all flags are set on server, so nothing should be updated
            imap.flagsFromServer = ImapFlagsBits.imapAllFlagsSet()
        }

        Record.saveAndWait()

        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertNil(messagesToBeSynced)

        guard let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folder: inbox) else {
            XCTFail()
            return
        }

        let expEmailsSynced = expectation(description: "expEmailsSynced")
        op.completionBlock = {
            expEmailsSynced.fulfill()
        }

        op.start()
        waitForExpectations(timeout: 300, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0, "all done")
        XCTAssertEqual(op.numberOfMessagesSynced, 0,
                       "no messages have been synced as all flag were already set before")
    }

    func testSyncFlagsToServerOperationAddFlags_someFlagsAlreadySetOnServer() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0,"Some messages exist to work with")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // all flags set locally ...
            imap.flagAnswered = true
            imap.flagDraft = true
            imap.flagFlagged = true
            // the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer
            imap.flagRecent = false
            imap.flagSeen = true
            imap.flagDeleted = true

            imap.flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
            imap.flagsFromServer.imapSetFlagBit(.answered)
            imap.flagsFromServer.imapSetFlagBit(.draft)
            imap.flagsFromServer.imapSetFlagBit(.flagged)
            // flagSeen differs ...
            imap.flagsFromServer.imapSetFlagBit(.deleted)

        }

        Record.saveAndWait()

        // ...so all messages should need to be synced
        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox,
            context: Record.Context.default)

        XCTAssertEqual(messagesToBeSynced?.count, messages.count,
                       "all messages should need to be synced")

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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0, "all done")
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
                       "flagDeleted changes, so all messages should be updated")
    }

    func testSyncFlagsToServerOperationAddFlags_addFlagAnswered() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // one flag that is not set on server has been set by the client,
            // so it has to be added.
            imap.flagAnswered = true
            imap.flagDraft = false
            imap.flagFlagged = false
            // (the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer)
            imap.flagRecent = false
            imap.flagSeen = false
            imap.flagDeleted = true
            // set the flag on server side
            imap.flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
            imap.flagsFromServer.imapSetFlagBit(.deleted)
        }

        Record.saveAndWait()

        // since a flag has be added on all messages, all messages need to be synced
        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertNotNil(messagesToBeSynced)
        XCTAssertEqual(messagesToBeSynced?.count, messages.count, "all messages need to be synced")

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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0,
                       "no messages have to be synced after syncing")
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
                       "all messages have been processed")
    }

    func testSyncFlagsToServerOperationAddFlags_addFlagDraft() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // one flag that is not set on server has been set by the client,
            // so it has to be added.
            imap.flagAnswered = false
            imap.flagDraft = true
            imap.flagFlagged = false
            // (the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer)
            imap.flagRecent = false
            imap.flagSeen = false
            imap.flagDeleted = true
            // set the flag on server side
            imap.flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
            imap.flagsFromServer.imapSetFlagBit(.deleted)
        }

        Record.saveAndWait()

        // since a flag has be added on all messages, all messages need to be synced
        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertNotNil(messagesToBeSynced)
        XCTAssertEqual(messagesToBeSynced?.count, messages.count, "all messages need to be synced")

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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0,
                       "no messages have to be synced after syncing")
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
                       "all messages have been processed")
    }

    func testSyncFlagsToServerOperationAddFlags_addFlagFlagged() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // one flag that is not set on server has been set by the client,
            // so it has to be added.
            imap.flagAnswered = false
            imap.flagDraft = false
            imap.flagFlagged = true
            // (the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer)
            imap.flagRecent = false
            imap.flagSeen = false
            imap.flagDeleted = true
            // set the flag on server side
            imap.flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
            imap.flagsFromServer.imapSetFlagBit(.deleted)
        }

        Record.saveAndWait()

        // since a flag has be added on all messages, all messages need to be synced
        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertNotNil(messagesToBeSynced)
        XCTAssertEqual(messagesToBeSynced?.count, messages.count, "all messages need to be synced")

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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0,
                       "no messages have to be synced after syncing")
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
                       "all messages have been processed")
    }

    func testSyncFlagsToServerOperationAddFlags_addFlagSeen() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // one flag that is not set on server has been set by the client,
            // so it has to be added.
            imap.flagAnswered = false
            imap.flagDraft = false
            imap.flagFlagged = false
            // (the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer)
            imap.flagRecent = false
            imap.flagSeen = true
            imap.flagDeleted = true
            // set the flag on server side
            imap.flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
            imap.flagsFromServer.imapSetFlagBit(.deleted)
        }

        Record.saveAndWait()

        // since a flag has be added on all messages, all messages need to be synced
        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertNotNil(messagesToBeSynced)
        XCTAssertEqual(messagesToBeSynced?.count, messages.count, "all messages need to be synced")

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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0,
                       "no messages have to be synced after syncing")
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
                       "all messages have been processed")
    }

    func testSyncFlagsToServerOperationAddFlags_addFlagDeleted() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // one flag that is not set on server has been set by the client,
            // so it has to be added.
            imap.flagAnswered = true
            imap.flagDraft = false
            imap.flagFlagged = false
            // (the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer)
            imap.flagRecent = false
            imap.flagSeen = false
            imap.flagDeleted = true
            // set the flag on server side
            imap.flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
            imap.flagsFromServer.imapSetFlagBit(.answered)
        }

        Record.saveAndWait()

        // since a flag has be added on all messages, all messages need to be synced
        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertNotNil(messagesToBeSynced)
        XCTAssertEqual(messagesToBeSynced?.count, messages.count, "all messages need to be synced")

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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0,
                       "no messages have to be synced after syncing")
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
                       "all messages have been processed")
    }

    func testSyncFlagsToServerOperationRemoveFlags_allFlagsAlreadySetOnServer() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // no flag set locally ...
            imap.flagAnswered = false
            imap.flagDraft = false
            imap.flagFlagged = false
            // the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer
            imap.flagRecent = true
            imap.flagSeen = false
            imap.flagDeleted = false
            // ... but all flags set on server, so all flags have to be removed
            imap.flagsFromServer = ImapFlagsBits.imapAllFlagsSet()
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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0)
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
                       "all messages have been synced")
    }

    func testSyncFlagsToServerOperationRemoveFlags_noChanges() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // flagsCurrent == flagsFromServer, so no syncing should take place
            imap.flagAnswered = false
            imap.flagDraft = true
            imap.flagFlagged = false
            // (the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer)
            imap.flagRecent = false
            imap.flagSeen = true
            imap.flagDeleted = false
            // server flags
            imap.flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
            imap.flagsFromServer.imapSetFlagBit(.draft)
            imap.flagsFromServer.imapSetFlagBit(.seen)

        }

        Record.saveAndWait()

        // nothing changed, so no sync should take place
        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertNil(messagesToBeSynced)

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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0,
                       "no messages have to be synced after syncing")
        XCTAssertEqual(op.numberOfMessagesSynced, 0,
                       "no message has been processed")
    }

    func testSyncFlagsToServerOperationRemoveFlags_removeFlagAnswered() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // one flag that is set on server has been unset by the client,
            // so it has to be removed.
            imap.flagAnswered = false
            imap.flagDraft = true
            imap.flagFlagged = true
            // (the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer)
            imap.flagRecent = true
            imap.flagSeen = true
            imap.flagDeleted = false
            // set the flag on server side
            imap.flagsFromServer = ImapFlagsBits.imapAllFlagsSet()
            imap.flagsFromServer.imapUnSetFlagBit(.deleted)
        }

        Record.saveAndWait()

        // since a flag has be removed on all messages, all messages need to be synced
        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertNotNil(messagesToBeSynced)
        XCTAssertEqual(messagesToBeSynced?.count, messages.count, "all messages need to be synced")

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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0,
                       "no messages have to be synced after syncing")
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
                       "all messages have been processed")
    }

    func testSyncFlagsToServerOperationRemoveFlags_removeFlagDraft() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // one flag that is set on server has been unset by the client,
            // so it has to be removed.
            imap.flagAnswered = true
            imap.flagDraft = false
            imap.flagFlagged = true
            // (the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer)
            imap.flagRecent = true
            imap.flagSeen = true
            imap.flagDeleted = false
            // set the flag on server side
            imap.flagsFromServer = ImapFlagsBits.imapAllFlagsSet()
            imap.flagsFromServer.imapUnSetFlagBit(.deleted)
        }

        Record.saveAndWait()

        // since a flag has be removed on all messages, all messages need to be synced
        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertNotNil(messagesToBeSynced)
        XCTAssertEqual(messagesToBeSynced?.count, messages.count, "all messages need to be synced")

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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0,
                       "no messages have to be synced after syncing")
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
                       "all messages have been processed")
    }

    func testSyncFlagsToServerOperationRemoveFlags_removeFlagFlagged() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // one flag that is set on server has been unset by the client,
            // so it has to be removed.
            imap.flagAnswered = true
            imap.flagDraft = true
            imap.flagFlagged = false
            // (the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer)
            imap.flagRecent = true
            imap.flagSeen = true
            imap.flagDeleted = false
            // set the flag on server side
            imap.flagsFromServer = ImapFlagsBits.imapAllFlagsSet()
            imap.flagsFromServer.imapUnSetFlagBit(.deleted)
        }

        Record.saveAndWait()

        // since a flag has be removed on all messages, all messages need to be synced
        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertNotNil(messagesToBeSynced)
        XCTAssertEqual(messagesToBeSynced?.count, messages.count, "all messages need to be synced")

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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0,
                       "no messages have to be synced after syncing")
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
                       "all messages have been processed")
    }

    func testSyncFlagsToServerOperationRemoveFlags_removeFlagSeen() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // one flag that is set on server has been unset by the client,
            // so it has to be removed.
            imap.flagAnswered = true
            imap.flagDraft = true
            imap.flagFlagged = true
            // (the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer)
            imap.flagRecent = true
            imap.flagSeen = false
            imap.flagDeleted = false
            // set the flag on server side
            imap.flagsFromServer = ImapFlagsBits.imapAllFlagsSet()
            imap.flagsFromServer.imapUnSetFlagBit(.deleted)
        }

        Record.saveAndWait()

        // since a flag has be removed on all messages, all messages need to be synced
        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertNotNil(messagesToBeSynced)
        XCTAssertEqual(messagesToBeSynced?.count, messages.count, "all messages need to be synced")

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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0,
                       "no messages have to be synced after syncing")
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
                       "all messages have been processed")
    }

    func testSyncFlagsToServerOperationRemoveFlags_removeFlagDeleted() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // one flag that is set on server has been unset by the client,
            // so it has to be removed.
            imap.flagAnswered = false
            imap.flagDraft = true
            imap.flagFlagged = true
            // (the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer)
            imap.flagRecent = true
            imap.flagSeen = true
            imap.flagDeleted = false
            // set the flag on server side
            imap.flagsFromServer = ImapFlagsBits.imapAllFlagsSet()
            imap.flagsFromServer.imapUnSetFlagBit(.answered)
        }

        Record.saveAndWait()

        // since a flag has be removed on all messages, all messages need to be synced
        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertNotNil(messagesToBeSynced)
        XCTAssertEqual(messagesToBeSynced?.count, messages.count, "all messages need to be synced")

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
            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
        })

        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0,
                       "no messages have to be synced after syncing")
        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
                       "all messages have been processed")
    }

    /**
     Proves that in the case of several `SyncFlagsToServerOperation`s
     scheduled very close to each other only the first will do the work,
     while the others will cancel early and not do anything.
     */
    func testSyncFlagsToServerOperationMulti() {
        fetchMessages()

        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
            XCTFail()
            return
        }

        guard let messages = inbox.messages?.sortedArray(
            using: [NSSortDescriptor(key: "sent", ascending: true)])
            as? [CdMessage] else {
                XCTFail()
                return
        }

        XCTAssertGreaterThan(messages.count, 0, "there are messages")

        for m in messages {
            XCTAssertNotNil(m.messageID)
            XCTAssertGreaterThan(m.uid, 0)
            guard let imap = m.imap else {
                XCTFail()
                break
            }
            // one flag that is set on server has been unset by the client,
            // so it has to be removed.
            imap.flagAnswered = true
            imap.flagDraft = true
            imap.flagFlagged = true
            // (the client must never change flagRecent according to RFC,
            // so we set it in state of flagsServer)
            imap.flagRecent = true
            imap.flagSeen = false
            imap.flagDeleted = false
            // set the flag on server side
            imap.flagsFromServer = ImapFlagsBits.imapAllFlagsSet()
            imap.flagsFromServer.imapUnSetFlagBit(.deleted)
        }

        Record.saveAndWait()

        // since a flag has be removed on all messages, all messages need to be synced
        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count, messages.count)

        let numSyncOpsToTrigger = 5
        var ops = [SyncFlagsToServerOperation]()
        for i in 1...numSyncOpsToTrigger {
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
            folder: inbox, context: Record.Context.default)
        XCTAssertEqual(messagesToBeSynced?.count ?? 0, 0)

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
            let opCreateSpecialFolders = CreateLocalSpecialFoldersOperation(account: cdAccount)
            let expFoldersStored = expectation(description: "expFoldersStored")
            opCreateSpecialFolders.completionBlock = {
                expFoldersStored.fulfill()
            }

            let queue = OperationQueue.init()
            queue.addOperation(opCreateSpecialFolders)
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
                print("\(acc.identity?.address) \(acc.identity?.userName)")
            }
        }
    }

    //MARK: - EncryptAndSendOperation

    func testEncryptAndSendOperation() {
        let session = PEPSession()
        TestUtil.importKeyByFileName(
            session, fileName: "Unit 1 unittest.ios.1@peptest.ch (0x9CB8DBCC) pub.asc")

        let from = CdIdentity.create()
        from.userName = cdAccount.identity?.userName ?? "Unit 004"
        from.address = cdAccount.identity?.address ?? "unittest.ios.4@peptest.ch"

        let toWithKey = CdIdentity.create()
        toWithKey.userName = "Unit 001"
        toWithKey.address = "unittest.ios.1@peptest.ch"

        let toWithoutKey = CdIdentity.create()
        toWithoutKey.userName = "Unit 002"
        toWithoutKey.address = "unittest.ios.2@peptest.ch"

        let folder = CdFolder.create()
        folder.uuid = MessageID.generate()
        folder.name = "Sent"
        folder.folderType = FolderType.sent.rawValue
        folder.account = cdAccount

        let imageFileName = "PorpoiseGalaxy_HubbleFraile_960.jpg"
        guard let imageData = TestUtil.loadDataWithFileName(imageFileName) else {
            XCTAssertTrue(false)
            return
        }

        // Build emails
        let numMails = 3
        for i in 1...numMails {
            let message = CdMessage.create()
            message.from = from
            message.parent = folder
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.sent = Date() as NSDate
            message.addTo(cdIdentity: toWithKey)

            // add attachment
            if i == numMails || i == numMails - 1 {
                let attachment = Attachment.create(
                    data: imageData, mimeType: "image/jpeg", fileName: imageFileName)
                let cdAttachment = CdAttachment.create(attachment: attachment)
                message.addAttachment(cdAttachment)
            }
            if i == numMails {
                // prevent encryption
                message.bcc = NSOrderedSet(object: toWithoutKey)
            }
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
        XCTAssertNotNil(EncryptAndSendOperation.retrieveNextMessage(context: Record.Context.default))
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
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()

        let imapLogin = LoginImapOperation(
            errorContainer: errorContainer, imapSyncData: imapSyncData)
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
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()

        let imapLogin = LoginImapOperation(
            errorContainer: errorContainer, imapSyncData: imapSyncData)
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

    func testTrashMessages() {
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()

        let imapLogin = LoginImapOperation(
            errorContainer: errorContainer, imapSyncData: imapSyncData)
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
            imapFields.flagDeleted = true
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
            imapSyncData: imapSyncData, errorContainer: errorContainer, folder: inboxFolder)
        let trashMailsOp2 = TrashMailsOperation(
            imapSyncData: imapSyncData, errorContainer: errorContainer, folder: draftsFolder)
        trashMailsOp2.addDependency(trashMailsOp1)
        trashMailsOp2.completionBlock = {
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
            XCTAssertTrue(imap.flagDeleted)
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
        cdFolder.name = "Whatever"
        cdFolder.uuid = "1"
        cdFolder.folderType = FolderType.inbox.rawValue
        cdFolder.account = cdAccount

        let cdMsg = CdMessage.create(messageID: "2", uid: 1, parent: cdFolder)

        let cdAttachWithoutSize = CdAttachment.create()
        cdAttachWithoutSize.data = "Some bytes".data(using: .utf8) as NSData?
        cdAttachWithoutSize.message = cdMsg
        cdAttachWithoutSize.length = 0

        Record.saveAndWait()

        let expAttachmentsFixed = expectation(description: "expAttachmentsFixed")
        let fixAttachmentsOp = FixAttachmentsOperation()
        fixAttachmentsOp.completionBlock = {
            expAttachmentsFixed.fulfill()
        }
        let queue = OperationQueue()
        queue.addOperation(fixAttachmentsOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(fixAttachmentsOp.hasErrors())
        })

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

    //MARK: - HELPER

    //flags all messages deleted on server and wipes out the local storage
    func flagAllMessagesDeletedOnServer() {
        setAllProperties()

        // fetch all folders and messages from server
        fetchFoldersAndWait()
        fetchMessagesForAllFoldersAndWait()

        //flag all messages deleted ...
        var msgs = CdMessage.all() as? [CdMessage] ?? []
        for m in msgs {
            m.imap?.flagDeleted = true
            m.imap?.flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
            print("####\nparent: \t \(m.parent?.name), m.imap?.flagDeleted: \(m.imap?.flagDeleted)")
        }
        Record.saveAndWait()

        // ... and sync the changes to server
        let folders = CdFolder.all()  as? [CdFolder] ?? []
        let numOpsToDo = folders.count
        var numOpsDone = 0
        let opQueue = OperationQueue()

        let expFolderSynced = expectation(description: "folders synced")

        var lastOperation:Operation?
        for folder in folders {
            guard let opSyncFlags = SyncFlagsToServerOperation(imapSyncData: self.imapSyncData, folder: folder) else {
                XCTFail()
                return
            }
            if lastOperation != nil {
                opSyncFlags.addDependency(lastOperation!)
            }

            opSyncFlags.completionBlock = {
                XCTAssertFalse(opSyncFlags.hasErrors())

                numOpsDone += 1
                if numOpsDone == numOpsToDo {
                    expFolderSynced.fulfill()
                }
            }

            lastOperation = opSyncFlags
            opQueue.addOperation(opSyncFlags)
        }

        waitForExpectations(timeout: 600) { error in
            XCTAssertNil(error)
        }

        // assure it worked out (all messages are flagged as deleted)
        setAllPropertiesNil()
        setAllProperties()

        fetchMessagesForAllFoldersAndWait()
        msgs = CdMessage.all() as? [CdMessage] ?? []
        for m in msgs {
            guard let imap = m.imap else {
                XCTFail()
                fatalError()
            }
           XCTAssertTrue(imap.flagDeleted, "All messages are deleted")
        }

        // back to virgine state
        setAllPropertiesNil()
    }

    func fetchFoldersAndWait() {
        let expFoldersFetched = expectation(description: "expFoldersFetched")

        let bgQueue = OperationQueue()
        let opLogin = LoginImapOperation(imapSyncData: imapSyncData)

        let opCreateSpecialFolders = CreateSpecialFoldersOperation(imapSyncData: imapSyncData)
        opCreateSpecialFolders.addDependency(opLogin)

        let opFetchFolders = FetchFoldersOperation(imapSyncData: imapSyncData)
        opFetchFolders.completionBlock = {
            expFoldersFetched.fulfill()
        }
        opFetchFolders.addDependency(opCreateSpecialFolders)

        bgQueue.addOperation(opLogin)
        bgQueue.addOperation(opCreateSpecialFolders)
        bgQueue.addOperation(opFetchFolders)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    private func setAllProperties() {
        persistentSetup = PersistentSetup()
        cdAccount = TestData().createWorkingCdAccount()
        cdAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        imapConnectInfo = cdAccount.imapConnectInfo
        smtpConnectInfo = cdAccount.smtpConnectInfo
        imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        XCTAssertNotNil(imapConnectInfo)
        XCTAssertNotNil(smtpConnectInfo)
        XCTAssertNotNil(imapSyncData)
    }

    private func setAllPropertiesNil() {
        connectionManager = nil
        cdAccount = nil
        imapConnectInfo = nil
        smtpConnectInfo = nil
        imapSyncData = nil
        persistentSetup = nil //whipes CoreData, including persistant store

    }

    func fetchMessages() {
        fetchMessagesAndWait(forFolderNamed: ImapSync.defaultImapInboxName)
    }

    func fetchMessagesForAllFoldersAndWait() {
        let folders = CdFolder.all()  as? [CdFolder] ?? []

        for folder in folders {
            guard let folderName = folder.name else {
                XCTFail("unnamed folder?!")
                continue
            }
            fetchMessagesAndWait(forFolderNamed: folderName)
        }
    }

    func fetchMessagesAndWait(forFolderNamed folderName: String) {
        let expMailsPrefetched = expectation(description: "expMailsPrefetched")

        let opLogin = LoginImapOperation(imapSyncData: imapSyncData)
        let op = FetchMessagesOperation(imapSyncData: imapSyncData,
                                        folderName: folderName)
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
    }
}
