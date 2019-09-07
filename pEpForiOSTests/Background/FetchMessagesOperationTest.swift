//
//  FetchMessagesOperationTest.swift
//  pEpForiOS
//
//  Created by buff on 09.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

@testable import MessageModel
@testable import pEpForiOS

class FetchMessagesOperationTest: CoreDataDrivenTestBase {
    // IOS-671 pEp app has two accounts. Someone sends a mail to both
    // (with both accounts in receipients).
    // Message must exist twice, once for each account, after fetching mails from server.
    // Commented as randomly failing and crashing. See IOS-1465.
//    func testMailSentToBothPepAccounts() {
//        // Setup 2 accounts
//        cdAccount.createRequiredFoldersAndWait(testCase: self)
//        moc.saveAndLogErrors()
//
//        let cdAccount2 = SecretTestData().createWorkingCdAccount(number: 1)
//        moc.saveAndLogErrors()
//        cdAccount2.createRequiredFoldersAndWait(testCase: self)
//        moc.saveAndLogErrors()
//
//        guard let id1 = cdAccount.identity,
//            let id2 = cdAccount2.identity else {
//                XCTFail("We all loose identity ...")
//                return
//        }
//
//        // Sync both acocunts and remember what we got before starting the actual test
//        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self)
//        let msgsBefore1 = cdAccount.allMessages(inFolderOfType: .inbox, sendFrom: id2)
//        let msgsBefore2 = cdAccount2.allMessages(inFolderOfType: .inbox, sendFrom: id2)
//
//        // Create mails from cdAccount2 with both accounts in receipients (cdAccount & cdAccount2)
//        let numMailsToSend = 2
//        let mailsToSend = try! TestUtil.createOutgoingMails(
//            cdAccount: cdAccount2,
//            fromIdentity: id2,
//            toIdentity: id1,
//            testCase: self,
//            numberOfMails: numMailsToSend,
//            withAttachments: false,
//            encrypt: false)
//        XCTAssertEqual(mailsToSend.count, numMailsToSend)
//
//        for mail in mailsToSend {
//            mail.addToTo(id2)
//            mail.pEpProtected = false // force unencrypted
//        }
//        moc.saveAndLogErrors()
//
//        // ... and send them.
//        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self)
//
//        // Sync once again to make sure we mirror the servers state (i.e. receive the sent mails)
//        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self)
//
//        // Now let's see what we got.
//        let msgsAfter1 = cdAccount.allMessages(inFolderOfType: .inbox, sendFrom: id2)
//        let msgsAfter2 = cdAccount2.allMessages(inFolderOfType: .inbox, sendFrom: id2)
//
//        XCTAssertEqual(msgsAfter1.count, msgsBefore1.count + numMailsToSend)
//        XCTAssertEqual(msgsAfter2.count, msgsBefore2.count + numMailsToSend)
//    }

    // IOS-615 (Only) the first email in an Yahoo account gets duplicated locally
    // on every sync cycle
    func testMailsNotDuplicated() {
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()

        // fetch emails in inbox ...
        let imapLogin = LoginImapOperation(parentName: #function, errorContainer: errorContainer,
                                           imapSyncData: imapSyncData)
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
        syncFoldersOp.completionBlock = { [weak self] in
            guard let me = self else {
                pEpForiOS.Log.shared.errorAndCrash("Lost myself")
                return
            }
            syncFoldersOp.completionBlock = nil
            guard let _ = CdFolder.all(in: me.moc) as? [CdFolder] else {
                XCTFail("No folders?")
                return
            }
            expFoldersFetched.fulfill()
        }

        let expFoldersCreated = expectation(description: "expFoldersCreated")
        let createRequiredFoldersOp = CreateRequiredFoldersOperation(parentName: #function,
                                                                     imapSyncData: imapSyncData)
        createRequiredFoldersOp.addDependency(syncFoldersOp)
        createRequiredFoldersOp.completionBlock = { [weak self] in
            guard let me = self else {
                pEpForiOS.Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let _ = CdFolder.all(in: me.moc) as? [CdFolder] else {
                XCTFail("No folders?")
                return
            }
            expFoldersCreated.fulfill()
        }

        let queue = OperationQueue()
        queue.addOperation(imapLogin)
        queue.addOperation(syncFoldersOp)
        queue.addOperation(createRequiredFoldersOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors())
            XCTAssertFalse(syncFoldersOp.hasErrors())
            XCTAssertFalse(createRequiredFoldersOp.hasErrors())
        })

        var msgCountBefore: Int? = 0
        // fetch messages
        let expMessagesSynced = expectation(description: "expMessagesSynced")
        let fetchOp = FetchMessagesOperation(parentName: #function, imapSyncData: imapSyncData)
        fetchOp.completionBlock = { [weak self] in
            guard let me = self else {
                pEpForiOS.Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let _ = CdMessage.all(in: me.moc) as? [CdMessage] else {
                XCTFail("No messages?")
                return
            }
            // ... remember count ...
            msgCountBefore = CdMessage.all(in: me.moc)?.count
            expMessagesSynced.fulfill()
        }
        queue.addOperation(fetchOp)

        // ... and fetch again.
        let expMessagesSynced2 = expectation(description: "expMessagesSynced2")
        let fetch2Op = FetchMessagesOperation(parentName: #function, imapSyncData: imapSyncData)
        fetch2Op.completionBlock = { [weak self] in
            guard let me = self else {
                pEpForiOS.Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let _ = CdMessage.all(in: me.moc) as? [CdMessage] else {
                XCTFail("No messages?")
                return
            }
            let msgCountAfter = CdMessage.all(in: me.moc)?.count
            // no mail should no have been dupliccated
            XCTAssertEqual(msgCountBefore, msgCountAfter)
            expMessagesSynced2.fulfill()
        }
        fetch2Op.addDependency(fetchOp)
        queue.addOperation(fetch2Op)
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(fetchOp.hasErrors())
            XCTAssertFalse(fetch2Op.hasErrors())
        })
    }
}
