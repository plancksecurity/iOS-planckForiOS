//IOS-2241 CRASHES
////
////  FetchMessagesOperationTest.swift
////  pEpForiOS
////
////  Created by buff on 09.08.17.
////  Copyright © 2017 p≡p Security S.A. All rights reserved.
////
//
//import XCTest
//import CoreData
//
//import pEpIOSToolbox
//@testable import MessageModel
//
//
//class FetchMessagesOperationTest: PersistentStoreDrivenTestBase {
//
//    // IOS-615 (Only) the first email in an Yahoo account gets duplicated locally
//    // on every sync cycle
//    func testMailsNotDuplicated() {
//        let imapConection = ImapConnection(connectInfo: imapConnectInfo)
//        let errorContainer = ErrorPropagator()
//
//        // fetch emails in inbox ...
//        let imapLogin = LoginImapOperation(parentName: #function,
//                                           errorContainer: errorContainer,
//                                           imapConnection: imapConection)
//
//        let expFoldersFetched = expectation(description: "expFoldersFetched")
//        let syncFoldersOp = SyncFoldersFromServerOperation(parentName: #function,
//                                                           imapConnection: imapConection)
//        syncFoldersOp.addDependency(imapLogin)
//        syncFoldersOp.completionBlock = { [weak self] in
//            guard let me = self else {
//                Log.shared.errorAndCrash("Lost myself")
//                return
//            }
//            syncFoldersOp.completionBlock = nil
//            guard let _ = CdFolder.all(in: me.moc) as? [CdFolder] else {
//                XCTFail("No folders?")
//                return
//            }
//            expFoldersFetched.fulfill()
//        }
//
//        let expFoldersCreated = expectation(description: "expFoldersCreated")
//        let createRequiredFoldersOp = CreateRequiredFoldersOperation(parentName: #function,
//                                                                     imapConnection: imapConection)
//        createRequiredFoldersOp.addDependency(syncFoldersOp)
//        createRequiredFoldersOp.completionBlock = { [weak self] in
//            guard let me = self else {
//                Log.shared.errorAndCrash("Lost myself")
//                return
//            }
//            guard let _ = CdFolder.all(in: me.moc) as? [CdFolder] else {
//                XCTFail("No folders?")
//                return
//            }
//            expFoldersCreated.fulfill()
//        }
//
//        let queue = OperationQueue()
//        queue.addOperation(imapLogin)
//        queue.addOperation(syncFoldersOp)
//        queue.addOperation(createRequiredFoldersOp)
//
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(imapLogin.hasErrors)
//            XCTAssertFalse(syncFoldersOp.hasErrors)
//            XCTAssertFalse(createRequiredFoldersOp.hasErrors)
//        })
//
//        var msgCountBefore: Int? = 0
//        // fetch messages
//        let expMessagesSynced = expectation(description: "expMessagesSynced")
//        let fetchOp = FetchMessagesInImapFolderOperation(parentName: #function,
//                                                         imapConnection: imapConection)
//        fetchOp.completionBlock = { [weak self] in
//            guard let me = self else {
//                Log.shared.errorAndCrash("Lost myself")
//                return
//            }
//            guard let _ = CdMessage.all(in: me.moc) as? [CdMessage] else {
//                XCTFail("No messages?")
//                return
//            }
//            // ... remember count ...
//            msgCountBefore = CdMessage.all(in: me.moc)?.count
//            expMessagesSynced.fulfill()
//        }
//        queue.addOperation(fetchOp)
//
//        // ... and fetch again.
//        let expMessagesSynced2 = expectation(description: "expMessagesSynced2")
//        let fetch2Op = FetchMessagesInImapFolderOperation(parentName: #function,
//                                                          imapConnection: imapConection)
//        fetch2Op.completionBlock = { [weak self] in
//            guard let me = self else {
//                Log.shared.errorAndCrash("Lost myself")
//                return
//            }
//            guard let _ = CdMessage.all(in: me.moc) as? [CdMessage] else {
//                XCTFail("No messages?")
//                return
//            }
//            let msgCountAfter = CdMessage.all(in: me.moc)?.count
//            // no mail should no have been dupliccated
//            XCTAssertEqual(msgCountBefore, msgCountAfter)
//            expMessagesSynced2.fulfill()
//        }
//        fetch2Op.addDependency(fetchOp)
//        queue.addOperation(fetch2Op)
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(fetchOp.hasErrors)
//            XCTAssertFalse(fetch2Op.hasErrors)
//        })
//    }
//}
