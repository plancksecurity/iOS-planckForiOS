//
//  TrashMailsOperationTest.swift
//  pEpForiOS
//
//  Created by buff on 21.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import CoreData
import MessageModel

class TrashMailsOperationTest: CoreDataDrivenTestBase {
    var errorContainer = ErrorContainer()
    var queue = OperationQueue()

    override func setUp() {
        super.setUp()
        errorContainer = ErrorContainer()
        queue = OperationQueue()
    }

    // MARK: - Sync Trash With Server Enabled

    func testTrashCdMessages_powerUser() {
        let syncTrashWithServer = true

        loginAndWait()

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
            message.uuid = "test_" + UUID().uuidString
            message.from = from
            if i == 1 {
                message.parent = draftsFolder
            } else {
                message.parent = inboxFolder
            }
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.sendStatus = SendStatus.none
            message.addTo(cdIdentity: to)
            let imapFields = CdImapFields.create()
            let imapFlags = CdImapFlags.create()
            imapFields.localFlags = imapFlags
            imapFlags.flagDeleted = true
            imapFields.trashedStatus = Message.TrashedStatus.shouldBeTrashed
            message.imap = imapFields
            originalMessages.append(message)
        }
        Record.saveAndWait()

        let foldersWithTrashedMessages = HandleMessagesMarkedAsShouldBeTrashedOperation.foldersWithTrashedMessages(
            context: Record.Context.main)
        XCTAssertEqual(foldersWithTrashedMessages.count, 2)
        if inboxFolder.name ?? "" < draftsFolder.name ?? "" {
            XCTAssertEqual(foldersWithTrashedMessages[safe: 0], inboxFolder)
            XCTAssertEqual(foldersWithTrashedMessages[safe: 1], draftsFolder)
        } else {
            XCTAssertEqual(foldersWithTrashedMessages[safe: 1], inboxFolder)
            XCTAssertEqual(foldersWithTrashedMessages[safe: 0], draftsFolder)
        }

        if let msgs = CdMessage.all() as? [CdMessage] {
            for m in msgs {
                XCTAssertNotNil(m.messageID)
                XCTAssertTrue(m.parent?.folderType == FolderType.inbox ||
                    m.parent?.folderType == FolderType.drafts)
                XCTAssertEqual(m.uid, Int32(0))
                XCTAssertEqual(m.sendStatus, SendStatus.none)
                XCTAssertEqual(m.imap?.trashedStatus, Message.TrashedStatus.shouldBeTrashed)
            }
        } else {
            XCTFail("No mesages?")
        }

        let expTrashed = expectation(description: "expTrashed")
        let trashMailsOpInbox = HandleMessagesMarkedAsShouldBeTrashedOperation(
            parentName: #function,
            imapSyncData: imapSyncData, errorContainer: errorContainer, folder: inboxFolder,
            syncTrashWithServer: syncTrashWithServer)
        let trashMailsOpDrafts = HandleMessagesMarkedAsShouldBeTrashedOperation(
            parentName: #function,
            imapSyncData: imapSyncData, errorContainer: errorContainer, folder: draftsFolder,
            syncTrashWithServer: syncTrashWithServer)
        trashMailsOpDrafts.addDependency(trashMailsOpInbox)
        trashMailsOpDrafts.completionBlock = {
            trashMailsOpDrafts.completionBlock = nil
            expTrashed.fulfill()
        }

        queue.addOperation(trashMailsOpInbox)
        queue.addOperation(trashMailsOpDrafts)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(trashMailsOpInbox.hasErrors())
            XCTAssertFalse(trashMailsOpDrafts.hasErrors())
        })

        Record.Context.main.refreshAllObjects()
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
            XCTAssertFalse(fetchTrashOp.hasErrors())
        })

        // Get uuids of messages in trash folder
        let trashed = trashFolder.allMessages()
        let decryptedTrashUUIDs = trashed.map { (cdEncryptedMessage: CdMessage) -> String in
            let decrypted = try! PEPSession().decryptMessage(
                cdEncryptedMessage.pEpMessage(),
                rating: nil,
                extraKeys: nil)
            return  decrypted.messageID!
        }

        for m in originalMessages {
            guard let mID = m.uuid else {
                XCTFail()
                continue
            }
            // Make sure the email now exists in the trash folder as well with same uuid
            if !decryptedTrashUUIDs.contains(mID) {
                XCTFail()
                break
            }

            guard let folder = m.parent else {
                XCTFail()
                continue
            }
            XCTAssertTrue(folder.folderType == FolderType.inbox ||
                folder.folderType == FolderType.drafts)
            guard let imap = m.imap else {
                XCTFail()
                continue
            }
            // Check the original message's flags
            XCTAssertTrue(imap.localFlags?.flagDeleted ?? false)
            XCTAssertEqual(imap.trashedStatus, Message.TrashedStatus.trashed)
        }
    }

    // MARK: - Sync Trash With Server Disabled

    func testTrashCdMessages_default() {
        let syncTrashWithServer = false
        loginAndWait()

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
            message.uuid = "test_" + UUID().uuidString
            message.from = from
            if i == 1 {
                message.parent = draftsFolder
            } else {
                message.parent = inboxFolder
            }
            message.shortMessage = "Some subject \(i)"
            message.longMessage = "Long message \(i)"
            message.longMessageFormatted = "<h1>Long HTML \(i)</h1>"
            message.sendStatus = SendStatus.none
            message.addTo(cdIdentity: to)
            let imapFields = CdImapFields.create()
            let imapFlags = CdImapFlags.create()
            imapFields.localFlags = imapFlags
            imapFlags.flagDeleted = true
            imapFields.trashedStatus = Message.TrashedStatus.shouldBeTrashed
            message.imap = imapFields
            originalMessages.append(message)
        }
        Record.saveAndWait()

        let foldersWithTrashedMessages = HandleMessagesMarkedAsShouldBeTrashedOperation.foldersWithTrashedMessages(
            context: Record.Context.main)
        XCTAssertEqual(foldersWithTrashedMessages.count, 2)
        if inboxFolder.name ?? "" < draftsFolder.name ?? "" {
            XCTAssertEqual(foldersWithTrashedMessages[safe: 0], inboxFolder)
            XCTAssertEqual(foldersWithTrashedMessages[safe: 1], draftsFolder)
        } else {
            XCTAssertEqual(foldersWithTrashedMessages[safe: 1], inboxFolder)
            XCTAssertEqual(foldersWithTrashedMessages[safe: 0], draftsFolder)
        }

        if let msgs = CdMessage.all() as? [CdMessage] {
            for m in msgs {
                XCTAssertNotNil(m.messageID)
                XCTAssertTrue(m.parent?.folderType == FolderType.inbox ||
                    m.parent?.folderType == FolderType.drafts)
                XCTAssertEqual(m.uid, Int32(0))
                XCTAssertEqual(m.sendStatus, SendStatus.none)
                XCTAssertEqual(m.imap?.trashedStatus, Message.TrashedStatus.shouldBeTrashed)
            }
        } else {
            XCTFail("No mesages?")
        }

        let expTrashed = expectation(description: "expTrashed")
        let trashMailsOpInbox = HandleMessagesMarkedAsShouldBeTrashedOperation(
            parentName: #function,
            imapSyncData: imapSyncData, errorContainer: errorContainer, folder: inboxFolder,
            syncTrashWithServer: syncTrashWithServer)
        let trashMailsOpDrafts = HandleMessagesMarkedAsShouldBeTrashedOperation(
            parentName: #function,
            imapSyncData: imapSyncData, errorContainer: errorContainer, folder: draftsFolder,
            syncTrashWithServer: syncTrashWithServer)
        trashMailsOpDrafts.addDependency(trashMailsOpInbox)
        trashMailsOpDrafts.completionBlock = {
            trashMailsOpDrafts.completionBlock = nil
            expTrashed.fulfill()
        }

        queue.addOperation(trashMailsOpInbox)
        queue.addOperation(trashMailsOpDrafts)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(trashMailsOpInbox.hasErrors())
            XCTAssertFalse(trashMailsOpDrafts.hasErrors())
        })

        Record.Context.main.refreshAllObjects()
        XCTAssertEqual(trashFolder.messages?.count ?? 0, numMails)

        for m in originalMessages {
            guard let folder = m.parent else {
                XCTFail()
                continue
            }
            XCTAssertTrue(folder.folderType == FolderType.inbox ||
                folder.folderType == FolderType.drafts)
            guard let imap = m.imap else {
                XCTFail()
                continue
            }
            // Check the original message's flags
            XCTAssertTrue(imap.localFlags?.flagDeleted ?? false)
            XCTAssertEqual(imap.trashedStatus, Message.TrashedStatus.trashed)
        }
    }

    // MARK: - HELPER

    private func loginAndWait() {
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

        queue.addOperation(imapLogin)
        queue.addOperation(fetchFoldersOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors())
            XCTAssertFalse(fetchFoldersOp.hasErrors())
        })
    }
}
