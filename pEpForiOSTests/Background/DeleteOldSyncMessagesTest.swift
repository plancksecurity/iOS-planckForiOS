//
//  DeleteOldSyncMessagesTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 30.07.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
@testable import pEpForiOS

class DeleteOldSyncMessagesTest: CoreDataDrivenTestBase {
    func testDeleteAndNotDelete() {
        let allMessages1 = CdMessage.all() as? [CdMessage] ?? []
        XCTAssertEqual(allMessages1.count, 0)

        let inbox = CdFolder(context: moc)
        inbox.folderType = .inbox
        inbox.account = cdAccount
        inbox.name = ImapSync.defaultImapInboxName

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
            XCTAssertFalse(opDelete.hasErrors())
        })

        moc.refreshAllObjects()

        XCTAssertTrue(syncMessageFromYesterday.isImapDeleted())
        XCTAssertFalse(syncMessageFresh.isImapDeleted())
    }

    func testSyncMessagesWithoutSentDate() {
        let allMessages1 = CdMessage.all() as? [CdMessage] ?? []
        XCTAssertEqual(allMessages1.count, 0)

        let inbox = CdFolder(context: moc)
        inbox.folderType = .inbox
        inbox.account = cdAccount
        inbox.name = ImapSync.defaultImapInboxName

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
            XCTAssertFalse(opDelete.hasErrors())
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

        // TODO: kPepHeaderAutoConsume once moved to MM
        autoConsumeHeader.name = "pEp-auto-consume"

        // TODO kPepValueAutoConsumeYes once moved to MM
        autoConsumeHeader.value = "yes"

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
