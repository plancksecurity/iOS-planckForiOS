//IOS-2241 CRASHES
//
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
//
//class SyncFlagsToServerOperationTest: PersistentStoreDrivenTestBase {
//
//    // MARK: - SyncFlagsToServerOperation
//
//    func testEmpty() {
//        TestUtil.syncAndWait(testCase: self)
//
//        guard let inbox = CdFolder.by(folderType: .inbox, account: cdAccount) else {
//            XCTFail()
//            return
//        }
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
//        let expEmailsSynced = expectation(description: "expEmailsSynced")
//        op.completionBlock = {
//            op.completionBlock = nil
//            expEmailsSynced.fulfill()
//        }
//
//        op.start()
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(op.hasErrors)
//        })
//
//        XCTAssertEqual(op.numberOfMessagesSynced, 0)
//    }
//
//    func testSyncFlagsToServerOperation() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
//            imap.localFlags = localFlags
//            localFlags.flagFlagged = !localFlags.flagFlagged
//        }
//
//        moc.saveAndLogErrors()
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
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count)
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0)
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count)
//    }
//
//    func testAddFlags_changeAllFlagsExceptDelete() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//            serverFlags.update(rawValue16: ImapFlagsBits.imapNoFlagsSet())
//
//            XCTAssertNotEqual(m.imap?.localFlags?.flagAnswered, m.imap?.serverFlags?.flagAnswered)
//        }
//
//        moc.saveAndLogErrors()
//
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count)
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0)
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count)
//    }
//
//    func testAddFlags_allFlagsAlreadySetOnServer() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//            serverFlags.update(rawValue16: ImapFlagsBits.imapAllFlagsSet())
//        }
//
//        moc.saveAndLogErrors()
//
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0)
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0, "all done")
//        XCTAssertEqual(op.numberOfMessagesSynced, 0,
//                       "no messages have been synced as all flag were already set before")
//    }
//
//    func testAddFlags_someFlagsAlreadySetOnServer() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
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
//        moc.saveAndLogErrors()
//
//        // ...so all messages should need to be synced
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//
//        XCTAssertEqual(messagesToBeSynced.count, messages.count,
//                       "all messages should need to be synced")
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0, "all done")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "flagDeleted changes, so all messages should be updated")
//    }
//
//    func testAddFlags_addFlagAnswered() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        moc.saveAndLogErrors()
//
//        // since a flag has be added on all messages, all messages need to be synced
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testAddFlags_addFlagDraft() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        moc.saveAndLogErrors()
//
//        // since a flag has be added on all messages, all messages need to be synced
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testAddFlags_addFlagFlagged() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        moc.saveAndLogErrors()
//
//        // since a flag has be added on all messages, all messages need to be synced
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(
//            folder: inbox, context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testAddFlags_addFlagSeen() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        moc.saveAndLogErrors()
//
//        // since a flag has be added on all messages, all messages need to be synced
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testRemoveFlags_allFlagsAlreadySetOnServer() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//            serverFlags.update(rawValue16: ImapFlagsBits.imapNoFlagsSet())
//        }
//
//        moc.saveAndLogErrors()
//
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0)
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0)
//        XCTAssertEqual(op.numberOfMessagesSynced, 0, "no message has been synced")
//    }
//
//    func testRemoveFlags_noChanges() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.draft)
//            theBits.imapSetFlagBit(.seen)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        moc.saveAndLogErrors()
//
//        // nothing changed, so no sync should take place
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0)
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, 0,
//                       "no message has been processed")
//    }
//
//    func testRemoveFlags_removeFlagAnswered() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        moc.saveAndLogErrors()
//
//        // since a flag has be removed on all messages, all messages need to be synced
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testRemoveFlags_removeFlagDraft() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        moc.saveAndLogErrors()
//
//        // since a flag has be removed on all messages, all messages need to be synced
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testRemoveFlags_removeFlagFlagged() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        moc.saveAndLogErrors()
//
//        // since a flag has be removed on all messages, all messages need to be synced
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testRemoveFlags_removeFlagSeen() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        moc.saveAndLogErrors()
//
//        // since a flag has be removed on all messages, all messages need to be synced
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, 0,
//                       "no messages have to be synced after syncing")
//        XCTAssertEqual(op.numberOfMessagesSynced, messages.count,
//                       "all messages have been processed")
//    }
//
//    func testRemoveFlags_removeFlagDeleted() {
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.answered)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        moc.saveAndLogErrors()
//
//        // since a flag has be removed on all messages, all messages need to be synced
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count, "all messages need to be synced")
//
//        let op = SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                        folderID: inbox.objectID)
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
//            XCTAssertFalse(op.hasErrors, "\(op.error!)")
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
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
//        TestUtil.syncAndWait(testCase: self)
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
//            let localFlags = imap.localFlags ?? CdImapFlags(context: moc)
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
//            let serverFlags = imap.serverFlags ?? CdImapFlags(context: moc)
//            imap.serverFlags = serverFlags
//            var theBits = ImapFlagsBits.imapNoFlagsSet()
//            theBits.imapSetFlagBit(.deleted)
//            serverFlags.update(rawValue16: theBits)
//        }
//
//        moc.saveAndLogErrors()
//
//        // since a flag has be removed on all messages, all messages need to be synced
//        var messagesToBeSynced =
//            SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                      context: moc)
//        XCTAssertEqual(messagesToBeSynced.count, messages.count)
//
//        let numSyncOpsToTrigger = 5
//        var ops = [SyncFlagsToServerInImapFolderOperation]()
//        for i in 1...numSyncOpsToTrigger {
//            let op =
//                SyncFlagsToServerInImapFolderOperation(imapConnection: imapConnection,
//                                                       folderID: inbox.objectID)
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
//                XCTAssertFalse(op.hasErrors)
//            }
//        })
//
//        messagesToBeSynced = SyncFlagsToServerInImapFolderOperation.messagesToBeSynced(folder: inbox,
//                                                                                       context: moc)
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
//}
