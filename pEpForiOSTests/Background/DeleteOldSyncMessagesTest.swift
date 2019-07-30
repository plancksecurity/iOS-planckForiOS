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
    // MARK: - Tests

    func testSimple() {
        let allMessages1 = CdMessage.all() as? [CdMessage] ?? []
        XCTAssertEqual(allMessages1.count, 0)

        let inbox = CdFolder(context: moc)
        inbox.folderType = .inbox
        inbox.account = cdAccount
        inbox.name = ImapSync.defaultImapInboxName

        moc.saveAndLogErrors()

        syncMessages(parentName: #function,
                     folderObjectID: inbox.objectID,
                     expectedNumberOfMessages: 0)

        guard let myId = cdAccount.identity else {
            XCTFail()
            return
        }

        let syncMessage = CdMessage(context: moc)
        syncMessage.parent = inbox
        syncMessage.from = myId
        syncMessage.to = NSOrderedSet(array: [myId])
        syncMessage.sent = Date().addingTimeInterval(-24 * 60 * 60) // yesterday

        let autoConsumeHeader = CdHeaderField(context: moc)

        // TODO: kPepHeaderAutoConsume once moved to MM
        autoConsumeHeader.name = "pEp-auto-consume"

        // TODO kPepValueAutoConsumeYes once moved to MM
        autoConsumeHeader.value = "yes"

        syncMessage.addToOptionalFields(autoConsumeHeader)

        moc.saveAndLogErrors()

        syncMessages(parentName: #function,
                     folderObjectID: inbox.objectID,
                     expectedNumberOfMessages: 0)
    }

    // MARK: - Helpers

    private func syncMessages(parentName: String,
                              folderObjectID: NSManagedObjectID,
                              expectedNumberOfMessages: Int) {
        let opDelete = DeleteOldSyncMailsOperation(parentName: parentName)
        let opLogin = LoginImapOperation(parentName: parentName, imapSyncData: imapSyncData)
        opLogin.addDependency(opDelete)
        let opSyncFlags = SyncFlagsToServerOperation(parentName: #function,
                                                     imapSyncData: imapSyncData,
                                                     folderID: folderObjectID)
        opSyncFlags.addDependency(opLogin)

        let expEmailsSynced = expectation(description: "expEmailsSynced")

        opSyncFlags.completionBlock = {
            opSyncFlags.completionBlock = nil
            expEmailsSynced.fulfill()
        }

        let bgQueue = OperationQueue()
        bgQueue.addOperation(opDelete)
        bgQueue.addOperation(opLogin)
        bgQueue.addOperation(opSyncFlags)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opSyncFlags.hasErrors())
        })

        let allMessages2 = CdMessage.all() as? [CdMessage] ?? []
        XCTAssertEqual(allMessages2.count, expectedNumberOfMessages)
    }
}
