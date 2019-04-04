//!!!: NSManagedObjectContextObjectsDidChangeNotification.  -[__NSCFSet addObject:]: attempt to insert nil with userInfo (null)

/*
 [error] error: Serious application error.  Exception was caught during Core Data change processing.  This is usually a bug within an observer of NSManagedObjectContextObjectsDidChangeNotification.  -[__NSCFSet addObject:]: attempt to insert nil with userInfo (null)
 CoreData: error: Serious application error.  Exception was caught during Core Data change processing.  This is usually a bug within an observer of NSManagedObjectContextObjectsDidChangeNotification.  -[__NSCFSet addObject:]: attempt to insert nil with userInfo (null)
 2019-04-04 20:46:32.038043+0200 pEp[68712:2062523] *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[__NSCFSet addObject:]: attempt to insert nil'
 *** First throw call stack:
 (
 0   CoreFoundation                      0x0000000110cb76fb __exceptionPreprocess + 331
 1   libobjc.A.dylib                     0x000000010f6c7ac5 objc_exception_throw + 48
 2   CoreFoundation                      0x0000000110cb7555 +[NSException raise:format:] + 197
 3   CoreFoundation                      0x0000000110c93a7a -[__NSCFSet addObject:] + 202
 4   CoreData                            0x000000011065a811 -[NSManagedObjectContext(_NSInternalChangeProcessing) _processPendingUpdates:] + 385
 5   CoreData                            0x0000000110654f57 -[NSManagedObjectContext(_NSInternalChangeProcessing) _processRecentChanges:] + 1127
 6   CoreData                            0x0000000110658d48 -[NSManagedObjectContext save:] + 408
 7   MessageModel                        0x000000010cf67d55 $sSo22NSManagedObjectContextC12MessageModelE16saveAndLogErrorsyyF + 901
 8   MessageModel                        0x000000010d06d230 $s12MessageModel28ManagedObjectWrapperProtocolPAAE4saveyyF + 784
 9   MessageModel                        0x000000010cfd6856 $s12MessageModel02CdA0C10cdIdentity16pantomimeAddressAA0cE0CSo010CWInternetG0C_tFZ + 2534
 10  MessageModel                        0x000000010cfd380b $s12MessageModel02CdA0C14insertOrUpdate09pantomimeA07account07messageF0ACSgSo13CWIMAPMessageC_AA0C7AccountCSo09CWMessageF0CtFZ + 3755
 11  MessageModel                        0x000000010d12af8a $s12MessageModel28StorePrefetchedMailOperationC14insertOrUpdate09pantomimeA07accountAA02CdA0CSgSo13CWIMAPMessageC_AA0L7AccountCtF + 650
 12  MessageModel                        0x000000010d12a0aa $s12MessageModel28StorePrefetchedMailOperationC05storeA07contextySo22NSManagedObjectContextC_tF + 1834
 13  MessageModel                        0x000000010d129705 $s12MessageModel28StorePrefetchedMailOperationC4mainyyFyycfU_ + 917
 14  MessageModel                        0x000000010d129871 $s12MessageModel28StorePrefetchedMailOperationC4mainyyFyycfU_TA + 17
 15  MessageModel                        0x000000010cd6001e $sIeg_IeyB_TR + 142
 16  CoreData                            0x000000011067184a developerSubmittedBlockToNSManagedObjectContextPerform + 170
 17  libclang_rt.asan_iossim_dynamic.dylib 0x000000010bc987b4 asan_dispatch_call_block_and_release + 260
 18  libdispatch.dylib                   0x0000000113cacd02 _dispatch_client_callout + 8
 19  libdispatch.dylib                   0x0000000113cb3720 _dispatch_lane_serial_drain + 705
 20  libdispatch.dylib                   0x0000000113cb4261 _dispatch_lane_invoke + 398
 21  libdispatch.dylib                   0x0000000113cbcfcb _dispatch_workloop_worker_thread + 645
 22  libsystem_pthread.dylib             0x000000011408e611 _pthread_wqthread + 421
 23  libsystem_pthread.dylib             0x000000011408e3fd start_wqthread + 13
 )
 libc++abi.dylib: terminating with uncaught exception of type NSException
 (lldb)


 */////
////  SyncFlagsToServerOperationTest.swift
////  pEpForiOS
////
////  Created by buff on 28.07.17.
////  Copyright © 2017 p≡p Security S.A. All rights reserved.
////
//
//import XCTest
//import CoreData
//
//@testable import MessageModel
//@testable import pEpForiOS
//
//class SyncFlagsToServerOperationTest: CoreDataDrivenTestBase {
//
//    // MARK: - SyncFlagsToServerOperation
//
//    func testEmpty() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors())
//        })
//
//        XCTAssertEqual(op.numberOfMessagesSynced, 0)
//    }
//
//    func testSyncFlagsToServerOperation() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//            localFlags.flagFlagged = !localFlags.flagFlagged
//        }
//
//        Record.saveAndWait()
//
//        // redundant check that flagFlagged really has changed
//        guard let messages2 = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//        for m in messages2 {
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//            guard let serverFlags = imap.serverFlags else {
//                XCTFail()
//                break
//            }
//            guard let localFlags = imap.localFlags else {
//                XCTFail()
//                break
//            }
//            XCTAssertNotEqual(serverFlags.flagFlagged, localFlags.flagFlagged)
//        }
//
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count)
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//        op.start()
//
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0)
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count)
//    }
//
//    func testAddFlags_changeAllFlagsExceptDelete() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)]) as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            // all flags set locally, except delete
//            localFlags.flagAnswered = true
//            localFlags.flagDraft = true
//            localFlags.flagFlagged = true
//            localFlags.flagRecent = false
//            localFlags.flagSeen = true
//
//            // ...but no flags are set on server, so all flags have to be added
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//            serverFlags.update(rawValue16: ImapFlagsBits.imapNoFlagsSet())
//
//            XCTAssertNotEqual(m.imap?.localFlags?.flagAnswered, m.imap?.serverFlags?.flagAnswered)
//        }
//
//        Record.saveAndWait()
//
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count)
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0)
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count)
//    }
//
//    func testAddFlags_allFlagsAlreadySetOnServer() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            // all flags set locally ...
//            localFlags.flagAnswered = true
//            localFlags.flagDraft = true
//            localFlags.flagFlagged = true
//            // the client must never change flagRecent according to RFC,
//            // so we set it in state of flagsServer
//            localFlags.flagRecent = true
//            localFlags.flagSeen = true
//            localFlags.flagDeleted = true
//
//            // ...and all flags are set on server, so nothing should be updated
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//            serverFlags.update(rawValue16: ImapFlagsBits.imapAllFlagsSet())
//        }
//
//        Record.saveAndWait()
//
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0)
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: 300, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0, "all done")
//        XCTAssertEqual(op.numberOfMessagesSynced, 0,
//                       "no messages have been synced as all flag were already set before")
//    }
//
//    func testAddFlags_someFlagsAlreadySetOnServer() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0,"Some messages exist to work with")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            // all flags set locally ...
//            localFlags.flagAnswered = true
//            localFlags.flagDraft = true
//            localFlags.flagFlagged = true
//            // the client must never change flagRecent according to RFC,
//            // so we set it in state of flagsServer
//            localFlags.flagRecent = false
//            localFlags.flagSeen = true
//            localFlags.flagDeleted = true
//
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//
//            var flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
//            flagsFromServer.imapSetFlagBit(.answered)
//            flagsFromServer.imapSetFlagBit(.draft)
//            flagsFromServer.imapSetFlagBit(.flagged)
//            // flagSeen differs ...
//            flagsFromServer.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: flagsFromServer)
//        }
//
//        Record.saveAndWait()
//
//        // ...so all messages should need to be synced
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox,
//            context: Record.Context.main)
//
//        XCTAssertEqual(messagesToBeSynced.count, messages.count,
//                       "all messages should need to be synced")
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0, "all done")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "flagDeleted changes, so all messages should be updated")
//    }
//
//    func testAddFlags_addFlagAnswered() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            // one flag that is not set on server has been set by the client,
//            // so it has to be added.
//            localFlags.flagAnswered = true
//            localFlags.flagDraft = false
//            localFlags.flagFlagged = false
//            // (the client must never change flagRecent according to RFC,
//            // so we set it in state of flagsServer)
//            localFlags.flagRecent = false
//            localFlags.flagSeen = false
//            localFlags.flagDeleted = true
//
//            // set the flag on server side
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        Record.saveAndWait()
//
//        // since a flag has be added on all messages, all messages need to be synced
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testAddFlags_addFlagDraft() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            // one flag that is not set on server has been set by the client,
//            // so it has to be added.
//            localFlags.flagAnswered = false
//            localFlags.flagDraft = true
//            localFlags.flagFlagged = false
//            // (the client must never change flagRecent according to RFC,
//            // so we set it in state of flagsServer)
//            localFlags.flagRecent = false
//            localFlags.flagSeen = false
//            localFlags.flagDeleted = true
//
//            // set the flag on server side
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        Record.saveAndWait()
//
//        // since a flag has be added on all messages, all messages need to be synced
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testAddFlags_addFlagFlagged() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            // one flag that is not set on server has been set by the client,
//            // so it has to be added.
//            localFlags.flagAnswered = false
//            localFlags.flagDraft = false
//            localFlags.flagFlagged = true
//            // (the client must never change flagRecent according to RFC,
//            // so we set it in state of flagsServer)
//            localFlags.flagRecent = false
//            localFlags.flagSeen = false
//            localFlags.flagDeleted = true
//
//            // set the flag on server side
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        Record.saveAndWait()
//
//        // since a flag has be added on all messages, all messages need to be synced
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testAddFlags_addFlagSeen() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//            // one flag that is not set on server has been set by the client,
//            // so it has to be added.
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            localFlags.flagAnswered = false
//            localFlags.flagDraft = false
//            localFlags.flagFlagged = false
//            // (the client must never change flagRecent according to RFC,
//            // so we set it in state of flagsServer)
//            localFlags.flagRecent = false
//            localFlags.flagSeen = true
//            localFlags.flagDeleted = true
//
//            // set the flag on server side
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        Record.saveAndWait()
//
//        // since a flag has be added on all messages, all messages need to be synced
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testRemoveFlags_allFlagsAlreadySetOnServer() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//            // no flag set locally ...
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            localFlags.flagAnswered = false
//            localFlags.flagDraft = false
//            localFlags.flagFlagged = false
//            // \Recent should be ignored
//            localFlags.flagRecent = true
//            localFlags.flagSeen = false
//            localFlags.flagDeleted = false
//
//            // ... but all flags set on server, so all flags have to be removed
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//            serverFlags.update(rawValue16: ImapFlagsBits.imapNoFlagsSet())
//        }
//
//        Record.saveAndWait()
//
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0)
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0)
//        XCTAssertEqual(op.numberOfMessagesSynced, 0, "no message has been synced")
//    }
//
//    func testRemoveFlags_noChanges() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//            // flagsCurrent == flagsFromServer, so no syncing should take place
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            localFlags.flagAnswered = false
//            localFlags.flagDraft = true
//            localFlags.flagFlagged = false
//            // (the client must never change flagRecent according to RFC,
//            // so we set it in state of flagsServer)
//            localFlags.flagRecent = false
//            localFlags.flagSeen = true
//            localFlags.flagDeleted = false
//
//            // server flags
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.draft)
//            theBits.imapSetFlagBit(.seen)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        Record.saveAndWait()
//
//        // nothing changed, so no sync should take place
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0)
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, 0,
//                       "no message has been processed")
//    }
//
//    func testRemoveFlags_removeFlagAnswered() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//            // one flag that is set on server has been unset by the client,
//            // so it has to be removed.
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            localFlags.flagAnswered = false
//            localFlags.flagDraft = true
//            localFlags.flagFlagged = true
//            // (the client must never change flagRecent according to RFC,
//            // so we set it in state of flagsServer)
//            localFlags.flagRecent = true
//            localFlags.flagSeen = true
//            localFlags.flagDeleted = false
//
//            // set the flag on server side
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        Record.saveAndWait()
//
//        // since a flag has be removed on all messages, all messages need to be synced
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testRemoveFlags_removeFlagDraft() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//            // one flag that is set on server has been unset by the client,
//            // so it has to be removed.
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            localFlags.flagAnswered = true
//            localFlags.flagDraft = false
//            localFlags.flagFlagged = true
//            // (the client must never change flagRecent according to RFC,
//            // so we set it in state of flagsServer)
//            localFlags.flagRecent = true
//            localFlags.flagSeen = true
//            localFlags.flagDeleted = false
//
//            // set the flag on server side
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        Record.saveAndWait()
//
//        // since a flag has be removed on all messages, all messages need to be synced
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testRemoveFlags_removeFlagFlagged() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//            // one flag that is set on server has been unset by the client,
//            // so it has to be removed.
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            localFlags.flagAnswered = true
//            localFlags.flagDraft = true
//            localFlags.flagFlagged = false
//            // (the client must never change flagRecent according to RFC,
//            // so we set it in state of flagsServer)
//            localFlags.flagRecent = true
//            localFlags.flagSeen = true
//            localFlags.flagDeleted = false
//
//            // set the flag on server side
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        Record.saveAndWait()
//
//        // since a flag has be removed on all messages, all messages need to be synced
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testRemoveFlags_removeFlagSeen() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//            // one flag that is set on server has been unset by the client,
//            // so it has to be removed.
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            localFlags.flagAnswered = true
//            localFlags.flagDraft = true
//            localFlags.flagFlagged = true
//            // (the client must never change flagRecent according to RFC,
//            // so we set it in state of flagsServer)
//            localFlags.flagRecent = true
//            localFlags.flagSeen = false
//            localFlags.flagDeleted = false
//
//            // set the flag on server side
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        Record.saveAndWait()
//
//        // since a flag has be removed on all messages, all messages need to be synced
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testRemoveFlags_removeFlagDeleted() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//            // one flag that is set on server has been unset by the client,
//            // so it has to be removed.
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            localFlags.flagAnswered = false
//            localFlags.flagDraft = true
//            localFlags.flagFlagged = true
//            // (the client must never change flagRecent according to RFC,
//            // so we set it in state of flagsServer)
//            localFlags.flagRecent = true
//            localFlags.flagSeen = true
//            localFlags.flagDeleted = false
//
//            // set the flag on server side
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.answered)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        Record.saveAndWait()
//
//        // since a flag has be removed on all messages, all messages need to be synced
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors(), "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    /**
//     Proves that in the case of several `SyncFlagsToServerOperation`s
//     scheduled very close to each other only the first will do the work,
//     while the others will cancel early and not do anything.
//     */
//    func testSyncFlagsToServerOperationMulti() {
//        fetchMessages(parentName: #function)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//
//        guard let messages = inbox.messages?.sortedArray(
//            using: [NSSortDescriptor(key: "sent", ascending: true)])
//            as? [CdMessage] else {
//                XCTFail()
//                return
//        }
//
//        XCTAssertGreaterThan(messages.count, 0, "there are messages")
//
//        for m in messages {
//            XCTAssertNotNil(m.messageID)
//            XCTAssertGreaterThan(m.uid, 0)
//            guard let imap = m.imap else {
//                XCTFail()
//                break
//            }
//            // one flag that is set on server has been unset by the client,
//            // so it has to be removed.
//            let localFlags = imap.localFlags ?? CdImapFlags.create()
//            imap.localFlags = localFlags
//
//            localFlags.flagAnswered = true
//            localFlags.flagDraft = true
//            localFlags.flagFlagged = true
//            // (the client must never change flagRecent according to RFC,
//            // so we set it in state of flagsServer)
//            localFlags.flagRecent = true
//            localFlags.flagSeen = false
//            localFlags.flagDeleted = false
//
//            // set the flag on server side
//            let serverFlags = imap.serverFlags ?? CdImapFlags.create()
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        Record.saveAndWait()
//
//        // since a flag has be removed on all messages, all messages need to be synced
//        var messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count)
//
//        let numSyncOpsToTrigger = 5
//        var ops = [SyncFlagsToServerOperation]()
//        for i in 1...numSyncOpsToTrigger {
//            let op =
//                SyncFlagsToServerOperation(imapSyncData: imapSyncData, folderID: inbox.objectID)
//            let expEmailsSynced = expectation(description: "expEmailsSynced\(i)")
//            op.completionBlock = {
//                op.completionBlock = nil
//                expEmailsSynced.fulfill()
//            }
//            ops.append(op)
//        }
//
//        let backgroundQueue = OperationQueue()
//
//        // Serialize all ops
//        backgroundQueue.maxConcurrentOperationCount = 1
//
//        for op in ops {
//            backgroundQueue.addOperation(op)
//        }
//
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            for op in ops {
//                XCTAssertFalse(op.hasErrors())
//            }
//        })
//
//        messagesToBeSynced = SyncFlagsToServerOperation.messagesToBeSynced(
//            folder: inbox, context: Record.Context.main)
//        XCTAssertEqual(messagesToBeSynced.count, 0)
//
//        var first = true
//        for op in ops {
//            if first {
//                XCTAssertEqual(op.numberOfMessagesSynced, inbox.messages?.count)
//                first = false
//            } else {
//                XCTAssertEqual(op.numberOfMessagesSynced, 0)
//            }
//        }
//    }
//
//}
