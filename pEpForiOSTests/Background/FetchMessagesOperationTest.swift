//!!!:erious application error.  Exception was caught during Core Data change processing.  This is usually a bug within an observer of NSManagedObjectContextObjectsDidChangeNotification.  -[__NSCFSet addObject:]: attempt to insert nil with userInfo (null)

/*CoreData: error: Serious application error.  Exception was caught during Core Data change processing.  This is usually a bug within an observer of NSManagedObjectContextObjectsDidChangeNotification.  -[__NSCFSet addObject:]: attempt to insert nil with userInfo (null)
2019-04-04 20:42:20.009631+0200 pEp[68473:2055730] *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[__NSCFSet addObject:]: attempt to insert nil'
*** First throw call stack:
(
0   CoreFoundation                      0x000000010e9a26fb __exceptionPreprocess + 331
1   libobjc.A.dylib                     0x000000010d3baac5 objc_exception_throw + 48
2   CoreFoundation                      0x000000010e9a2555 +[NSException raise:format:] + 197
3   CoreFoundation                      0x000000010e97ea7a -[__NSCFSet addObject:] + 202
4   CoreData                            0x000000010e345811 -[NSManagedObjectContext(_NSInternalChangeProcessing) _processPendingUpdates:] + 385
5   CoreData                            0x000000010e33ff57 -[NSManagedObjectContext(_NSInternalChangeProcessing) _processRecentChanges:] + 1127
6   CoreData                            0x000000010e347415 -[NSManagedObjectContext(_NSInternalChangeProcessing) _prepareForPushChanges:] + 165
7   CoreData                            0x000000010e343dbb -[NSManagedObjectContext save:] + 523
8   MessageModel                        0x000000010ab00d55 $sSo22NSManagedObjectContextC12MessageModelE16saveAndLogErrorsyyF + 901
9   MessageModel                        0x000000010ac06230 $s12MessageModel28ManagedObjectWrapperProtocolPAAE4saveyyF + 784
10  MessageModel                        0x000000010ab6f856 $s12MessageModel02CdA0C10cdIdentity16pantomimeAddressAA0cE0CSo010CWInternetG0C_tFZ + 2534
11  MessageModel                        0x000000010ab6cd0f $s12MessageModel02CdA0C14insertOrUpdate09pantomimeA07account07messageF0ACSgSo13CWIMAPMessageC_AA0C7AccountCSo09CWMessageF0CtFZ + 5039
12  MessageModel                        0x000000010acc3f8a $s12MessageModel28StorePrefetchedMailOperationC14insertOrUpdate09pantomimeA07accountAA02CdA0CSgSo13CWIMAPMessageC_AA0L7AccountCtF + 650
13  MessageModel                        0x000000010acc30aa $s12MessageModel28StorePrefetchedMailOperationC05storeA07contextySo22NSManagedObjectContextC_tF + 1834
14  MessageModel                        0x000000010acc2705 $s12MessageModel28StorePrefetchedMailOperationC4mainyyFyycfU_ + 917
15  MessageModel                        0x000000010acc2871 $s12MessageModel28StorePrefetchedMailOperationC4mainyyFyycfU_TA + 17
16  MessageModel                        0x000000010a8f901e $sIeg_IeyB_TR + 142
17  CoreData                            0x000000010e35c84a developerSubmittedBlockToNSManagedObjectContextPerform + 170
18  libclang_rt.asan_iossim_dynamic.dylib 0x00000001098317b4 asan_dispatch_call_block_and_release + 260
19  libdispatch.dylib                   0x0000000111847d02 _dispatch_client_callout + 8
20  libdispatch.dylib                   0x000000011184e720 _dispatch_lane_serial_drain + 705
21  libdispatch.dylib                   0x000000011184f261 _dispatch_lane_invoke + 398
22  libdispatch.dylib                   0x0000000111857fcb _dispatch_workloop_worker_thread + 645
23  libsystem_pthread.dylib             0x0000000111c29611 _pthread_wqthread + 421
24  libsystem_pthread.dylib             0x0000000111c293fd start_wqthread + 13
)
libc++abi.dylib: terminating with uncaught exception of type NSException
*/

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
//@testable import MessageModel
//@testable import pEpForiOS
//
//class FetchMessagesOperationTest: CoreDataDrivenTestBase {
//    // IOS-671 pEp app has two accounts. Someone sends a mail to both
//    // (with both accounts in receipients).
//    // Message must exist twice, once for each account, after fetching mails from server.
//    // Commented as randomly failing and crashing. See IOS-1465.
////    func testMailSentToBothPepAccounts() {
////        // Setup 2 accounts
////        cdAccount.createRequiredFoldersAndWait(testCase: self)
////        Record.saveAndWait()
////
////        let cdAccount2 = SecretTestData().createWorkingCdAccount(number: 1)
////        Record.saveAndWait()
////        cdAccount2.createRequiredFoldersAndWait(testCase: self)
////        Record.saveAndWait()
////
////        guard let id1 = cdAccount.identity,
////            let id2 = cdAccount2.identity else {
////                XCTFail("We all loose identity ...")
////                return
////        }
////
////        // Sync both acocunts and remember what we got before starting the actual test
////        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self)
////        let msgsBefore1 = cdAccount.allMessages(inFolderOfType: .inbox, sendFrom: id2)
////        let msgsBefore2 = cdAccount2.allMessages(inFolderOfType: .inbox, sendFrom: id2)
////
////        // Create mails from cdAccount2 with both accounts in receipients (cdAccount & cdAccount2)
////        let numMailsToSend = 2
////        let mailsToSend = try! TestUtil.createOutgoingMails(
////            cdAccount: cdAccount2,
////            fromIdentity: id2,
////            toIdentity: id1,
////            testCase: self,
////            numberOfMails: numMailsToSend,
////            withAttachments: false,
////            encrypt: false)
////        XCTAssertEqual(mailsToSend.count, numMailsToSend)
////
////        for mail in mailsToSend {
////            mail.addToTo(id2)
////            mail.pEpProtected = false // force unencrypted
////        }
////        Record.saveAndWait()
////
////        // ... and send them.
////        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self)
////
////        // Sync once again to make sure we mirror the servers state (i.e. receive the sent mails)
////        TestUtil.syncAndWait(numAccountsToSync: 2, testCase: self)
////
////        // Now let's see what we got.
////        let msgsAfter1 = cdAccount.allMessages(inFolderOfType: .inbox, sendFrom: id2)
////        let msgsAfter2 = cdAccount2.allMessages(inFolderOfType: .inbox, sendFrom: id2)
////
////        XCTAssertEqual(msgsAfter1.count, msgsBefore1.count + numMailsToSend)
////        XCTAssertEqual(msgsAfter2.count, msgsBefore2.count + numMailsToSend)
////    }
//
//    // IOS-615 (Only) the first email in an Yahoo account gets duplicated locally
//    // on every sync cycle
//    func testMailsNotDuplicated() {
//        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
//        let errorContainer = ErrorContainer()
//
//        // fetch emails in inbox ...
//        let imapLogin = LoginImapOperation(parentName: #function, errorContainer: errorContainer,
//                                           imapSyncData: imapSyncData)
//        imapLogin.completionBlock = {
//            imapLogin.completionBlock = nil
//            XCTAssertNotNil(imapSyncData.sync)
//        }
//
//        let expFoldersFetched = expectation(description: "expFoldersFetched")
//        guard let syncFoldersOp = SyncFoldersFromServerOperation(parentName: #function,
//                                                                 imapSyncData: imapSyncData)
//            else {
//                XCTFail()
//                return
//        }
//        syncFoldersOp.addDependency(imapLogin)
//        syncFoldersOp.completionBlock = {
//            syncFoldersOp.completionBlock = nil
//            guard let _ = CdFolder.all() as? [CdFolder] else {
//                XCTFail("No folders?")
//                return
//            }
//            expFoldersFetched.fulfill()
//        }
//
//        let expFoldersCreated = expectation(description: "expFoldersCreated")
//        let createRequiredFoldersOp = CreateRequiredFoldersOperation(parentName: #function,
//                                                                     imapSyncData: imapSyncData)
//        createRequiredFoldersOp.addDependency(syncFoldersOp)
//        createRequiredFoldersOp.completionBlock = {
//            guard let _ = CdFolder.all() as? [CdFolder] else {
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
//            XCTAssertFalse(imapLogin.hasErrors())
//            XCTAssertFalse(syncFoldersOp.hasErrors())
//            XCTAssertFalse(createRequiredFoldersOp.hasErrors())
//        })
//
//        var msgCountBefore: Int? = 0
//        // fetch messages
//        let expMessagesSynced = expectation(description: "expMessagesSynced")
//        let fetchOp = FetchMessagesOperation(parentName: #function, imapSyncData: imapSyncData)
//        fetchOp.completionBlock = {
//            guard let _ = CdMessage.all() as? [CdMessage] else {
//                XCTFail("No messages?")
//                return
//            }
//            // ... remember count ...
//            msgCountBefore = CdMessage.all()?.count
//            expMessagesSynced.fulfill()
//        }
//        queue.addOperation(fetchOp)
//
//        // ... and fetch again.
//        let expMessagesSynced2 = expectation(description: "expMessagesSynced2")
//        let fetch2Op = FetchMessagesOperation(parentName: #function, imapSyncData: imapSyncData)
//        fetch2Op.completionBlock = {
//            guard let _ = CdMessage.all() as? [CdMessage] else {
//                XCTFail("No messages?")
//                return
//            }
//            let msgCountAfter = CdMessage.all()?.count
//            // no mail should no have been dupliccated
//            XCTAssertEqual(msgCountBefore, msgCountAfter)
//            expMessagesSynced2.fulfill()
//        }
//        fetch2Op.addDependency(fetchOp)
//        queue.addOperation(fetch2Op)
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(fetchOp.hasErrors())
//            XCTAssertFalse(fetch2Op.hasErrors())
//        })
//    }
//}
