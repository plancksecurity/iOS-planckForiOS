//
//  DeleteOldSyncMailsOperationTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 30.07.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS

class DeleteOldSyncMessagesTest: PersistentStoreDrivenTestBase {
    func testDeleteAndNotDeleteDueToDate() {
        let allMessages1 = CdMessage.all(in: moc) as? [CdMessage] ?? []
        XCTAssertEqual(allMessages1.count, 0)

        let inbox = CdFolder(context: moc)
        inbox.folderType = .inbox
        inbox.account = cdAccount
        inbox.name = ImapConnection.defaultInboxName

        guard let myId = cdAccount.identity else {
            XCTFail()
            return
        }

        let yesterday = Date().addingTimeInterval(-24 * 60 * 60)

        let syncMessageFromYesterday = createSyncMessage(folder: inbox,
                                                         ownIdentity: myId,
                                                         sentDate: yesterday)

        let syncMessageFresh = createSyncMessage(folder: inbox,
                                                 ownIdentity: myId,
                                                 sentDate: Date())
        moc.saveAndLogErrors()

        XCTAssertFalse(syncMessageFromYesterday.isImapDeleted())
        XCTAssertFalse(syncMessageFresh.isImapDeleted())

        let expSyncMailsDeleted = expectation(description: "expSyncMailsDeleted")
        let opDelete = DeleteOldSyncMailsOperation(parentName: #function)
        opDelete.completionBlock = {
            expSyncMailsDeleted.fulfill()
        }
        let bgQueue = OperationQueue()
        bgQueue.addOperation(opDelete)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opDelete.hasErrors)
        })

        moc.refreshAllObjects()

        XCTAssertTrue(syncMessageFromYesterday.isImapDeleted())
        XCTAssertFalse(syncMessageFresh.isImapDeleted())
    }

    func testNotDeletedDueToFolderType() {
        let allMessages1 = CdMessage.all(in: moc) as? [CdMessage] ?? []
        XCTAssertEqual(allMessages1.count, 0)

        let outbox = CdFolder(context: moc)
        outbox.folderType = .outbox
        outbox.account = cdAccount
        outbox.name = "Outbox"

        guard let myId = cdAccount.identity else {
            XCTFail()
            return
        }

        let yesterday = Date().addingTimeInterval(-24 * 60 * 60)

        let syncMessageInOutbox = createSyncMessage(folder: outbox,
                                                    ownIdentity: myId,
                                                    sentDate: yesterday)
        moc.saveAndLogErrors()

        XCTAssertFalse(syncMessageInOutbox.isImapDeleted())

        let expSyncMailsDeleted = expectation(description: "expSyncMailsDeleted")
        let opDelete = DeleteOldSyncMailsOperation(parentName: #function)
        opDelete.completionBlock = {
            expSyncMailsDeleted.fulfill()
        }
        let bgQueue = OperationQueue()
        bgQueue.addOperation(opDelete)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opDelete.hasErrors)
        })

        moc.refreshAllObjects()

        XCTAssertFalse(syncMessageInOutbox.isImapDeleted())
        XCTAssertFalse(syncMessageInOutbox.isDeleted)
    }

    func testSyncMessagesWithoutSentDate() {
        let allMessages1 = CdMessage.all(in: moc) as? [CdMessage] ?? []
        XCTAssertEqual(allMessages1.count, 0)

        let inbox = CdFolder(context: moc)
        inbox.folderType = .inbox
        inbox.account = cdAccount
        inbox.name = ImapConnection.defaultInboxName

        guard let myId = cdAccount.identity else {
            XCTFail()
            return
        }

        let syncMessageWithoutSent = createSyncMessage(folder: inbox,
                                                       ownIdentity: myId,
                                                       sentDate: nil)

        moc.saveAndLogErrors()

        XCTAssertFalse(syncMessageWithoutSent.isImapDeleted())

        let expSyncMailsDeleted = expectation(description: "expSyncMailsDeleted")
        let opDelete = DeleteOldSyncMailsOperation(parentName: #function)
        opDelete.completionBlock = {
            expSyncMailsDeleted.fulfill()
        }
        let bgQueue = OperationQueue()
        bgQueue.addOperation(opDelete)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opDelete.hasErrors)
        })

        moc.refreshAllObjects()

        XCTAssertFalse(syncMessageWithoutSent.isImapDeleted())
    }

    // MARK: - Helpers

    func createSyncMessage(folder: CdFolder,
                           ownIdentity: CdIdentity,
                           sentDate: Date?) -> CdMessage {
        let syncMessage = CdMessage(context: moc)
        syncMessage.parent = folder
        syncMessage.from = ownIdentity
        syncMessage.to = NSOrderedSet(array: [ownIdentity])
        syncMessage.sent = sentDate

        let autoConsumeHeader = CdHeaderField(context: moc)
        autoConsumeHeader.name = kPepHeaderAutoConsume
        autoConsumeHeader.value = kPepValueAutoConsumeYes

        syncMessage.addToOptionalFields(autoConsumeHeader)
        return syncMessage
    }
}

// MARK: - Test Extensions

extension CdMessage {
    func isImapDeleted() -> Bool {
        return imap?.localFlags?.flagDeleted ?? false
    }
}
