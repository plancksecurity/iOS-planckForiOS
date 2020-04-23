//
//  CdMessage+PantomimeTest.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 10/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

import PantomimeFramework
@testable import MessageModel
import pEpIOSToolbox

class CdMessage_PantomimeTest: PersistentStoreDrivenTestBase {
    // MARK: - StoreCommandForFlagsToRemoved / Add

    func testStoreCommandForFlagsToRemove_someServerFlagsSet() {
        let m = CdMessage(context: moc)
        m.imap = CdImapFields(context: moc)

        let localFlags = CdImapFlags(context: moc)
        m.imap?.localFlags = localFlags

        let serverFlags = CdImapFlags(context: moc)
        m.imap?.serverFlags = serverFlags

        m.uid = 1024
        var flagsFromServer = ImapFlagsBits.imapAllFlagsSet()
        flagsFromServer.imapUnSetFlagBit(.seen) // seen not set on server ...
        serverFlags.update(rawValue16: flagsFromServer)

        setAllCurrentImapFlags(of: m, to: true)

        // ... so it should not be removed

        // nothing has changed
        XCTAssertNil(m.storeCommandForUpdateFlags(to: .remove)?.0)

        // remove flags locally (while offline) and assure it's handled correctly
        localFlags.flagAnswered = false

        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .remove)!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered)")

        localFlags.flagDraft = false
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .remove)!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft)")

        localFlags.flagFlagged = false
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .remove)!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        localFlags.flagSeen = false
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .remove)!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        localFlags.flagDeleted = false
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .remove)!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft \\Flagged \\Deleted)")
    }

    func testStoreCommandForFlagsToAdd_noServerFlagsSet() {
        let m = CdMessage(context: moc)
        m.imap = CdImapFields(context: moc)

        let localFlags = CdImapFlags(context: moc)
        m.imap?.localFlags = localFlags

        m.uid = 1024
        setAllCurrentImapFlags(of: m, to: false)

        // nothing has changed
        XCTAssertNil(m.storeCommandForUpdateFlags(to: .add)?.0)

        // add flags locally (while offline) and assure it's handled correctly
        localFlags.flagAnswered = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered)")

        localFlags.flagDraft = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft)")

        localFlags.flagFlagged = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        localFlags.flagSeen = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft \\Flagged \\Seen)")

        localFlags.flagDeleted = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0, "UID STORE 1024 +FLAGS.SILENT " +
            "(\\Answered \\Draft \\Flagged \\Seen \\Deleted)")
    }

    func testStoreCommandForFlagsToAdd_someServerFlagsSet() {
        let m = CdMessage(context: moc)
        m.imap = CdImapFields(context: moc)

        let localFlags = CdImapFlags(context: moc)
        m.imap?.localFlags = localFlags

        let serverFlags = CdImapFlags(context: moc)
        m.imap?.serverFlags = serverFlags

        m.uid = 1024
        var flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
        flagsFromServer.imapSetFlagBit(.seen) // flagSeen is set on server ...
        serverFlags.update(rawValue16: flagsFromServer)
        setAllCurrentImapFlags(of: m, to: false)

        // ... so //Seen must not be added

        // nothing has changed
        XCTAssertNil(m.storeCommandForUpdateFlags(to: .add)?.0)

        // add flags locally (while offline) and assure it's handled correctly
        localFlags.flagAnswered = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered)")

        localFlags.flagDraft = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft)")

        localFlags.flagFlagged = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        localFlags.flagSeen = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        localFlags.flagDeleted = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0, "UID STORE 1024 +FLAGS.SILENT " +
            "(\\Answered \\Draft \\Flagged \\Deleted)")
    }

    func testInsertOrUpdatePantomimeMessage() {
        let cdAccount = SecretTestData().createWorkingCdAccount(context: moc)

        let folder = CdFolder(context: moc)
        folder.account = cdAccount
        folder.name = ImapConnection.defaultInboxName

        guard
            let data = MiscUtil.loadData(bundleClass: CdMessage_PantomimeTest.self,
                                         fileName: "UnencryptedHTMLMail.txt"),
            let message = CWIMAPMessage(data: data) else {
                XCTAssertTrue(false)
                return
        }
        message.setFolder(CWIMAPFolder(name: ImapConnection.defaultInboxName))
        let msg = CdMessage.insertOrUpdate(pantomimeMessage: message,
                                           account: cdAccount,
                                           messageUpdate: CWMessageUpdate(),
                                           context: moc)
        XCTAssertNotNil(msg)
        if let m = msg {
            XCTAssertNotNil(m.longMessage)
            XCTAssertNotNil(m.longMessageFormatted)
        }
    }

    //IOS-211 hi_there
    func testInsertOrUpdatePantomimeMessage_attachmentNotDuplicated_file1() {
        let folder = CdFolder(context: moc)
        folder.account = cdAccount
        folder.name = ImapConnection.defaultInboxName

        guard
            let messageWithKeyAndPdfAttached = MiscUtil.loadData(bundleClass: CdMessage_PantomimeTest.self,
                                                                 fileName: "IOS-211_hi_there.txt"),
            let message = CWIMAPMessage(data: messageWithKeyAndPdfAttached) else {
                XCTAssertTrue(false)
                return
        }
        let nonZeroValue = UInt(1)
        message.setUID(nonZeroValue)
        message.setFolder(CWIMAPFolder(name: ImapConnection.defaultInboxName))
        guard let _ = CdMessage.insertOrUpdate(pantomimeMessage: message,
                                               account: cdAccount,
                                               messageUpdate: CWMessageUpdate(),
                                               context: moc)
            else {
                XCTFail("error parsing message")
                return
        }
        XCTAssertEqual(CdMessage.all(in: moc)?.count, 1)
        guard let testee = CdMessage.search(message: message,
                                            inAccount: cdAccount,
                                            context: moc) else {
            XCTFail("No message")
            return
        }
        let keyAttachment = 1
        let pdfAttachment = 1;
        let expectedNumAttatchments = keyAttachment + pdfAttachment
        XCTAssertTrue(testee.attachments?.count == expectedNumAttatchments)
    }
    
    //IOS-211 pdfMail
    func testInsertOrUpdatePantomimeMessage_attachmentNotDuplicated_file2() {
        let folder = CdFolder(context: moc)
        folder.account = cdAccount
        folder.name = ImapConnection.defaultInboxName
        
        guard
            let messageWithKeyAndPdfAttached = MiscUtil.loadData(bundleClass: CdMessage_PantomimeTest.self,
                                                                 fileName: "IOS-211-pdfEmail.txt"),
            let message = CWIMAPMessage(data: messageWithKeyAndPdfAttached) else {
                XCTAssertTrue(false)
                return
        }
        let nonZeroValue = UInt(1)
        message.setUID(nonZeroValue)
        message.setFolder(CWIMAPFolder(name: ImapConnection.defaultInboxName))
        guard let _ = CdMessage.insertOrUpdate(
            pantomimeMessage: message, account: cdAccount, messageUpdate: CWMessageUpdate(),
            context: moc) else {
                XCTFail("error parsing message")
                return
        }
        XCTAssertEqual(CdMessage.all(in: moc)?.count, 1)
        guard let testee = CdMessage.search(message: message, inAccount: cdAccount, context: moc) else {
            XCTFail("No message")
            return
        }
        let pdfAttachment = 1;
        
        XCTAssertTrue(testee.attachments?.count == pdfAttachment)
    }

    func testUpdateFromServer() {
        let m = createCdMessageForFlags()
        let cwFlags = CWFlags()

        // Server adds .seen, user just flagged -> both
        m.imapFields().localFlags?.flagFlagged = true
        cwFlags.add(.seen)
        XCTAssertTrue(cwFlags.contain(.seen))
        m.updateFromServer(cwFlags: cwFlags, context: moc)
        XCTAssertTrue(m.imapFields().localFlags?.flagFlagged ?? false)
        XCTAssertTrue(m.imapFields().localFlags?.flagSeen ?? false)
        XCTAssertEqual(m.imapFields().serverFlags?.rawFlagsAsShort(), cwFlags.rawFlagsAsShort())

        // No user action, server adds .seen -> .seen locally (ServerFags)
        m.imapFields().localFlags?.reset()
        m.imapFields().serverFlags?.reset()
        m.updateFromServer(cwFlags: cwFlags, context: moc)
        XCTAssertTrue(m.imapFields().localFlags?.flagSeen ?? false)
        let invalid = Int16(-1)
        XCTAssertEqual(m.imapFields().serverFlags?.rawFlagsAsShort() ?? invalid, cwFlags.rawFlagsAsShort())

        // Conflict: User just unflagged, that should win over the data from the server
        m.imapFields().localFlags?.reset()
        m.imapFields().serverFlags?.reset()
        cwFlags.removeAll()
        cwFlags.add(.flagged)
        m.imapFields().serverFlags?.flagFlagged = true
        m.updateFromServer(cwFlags: cwFlags, context: moc)
        XCTAssertFalse(m.imapFields().localFlags?.flagFlagged ?? true)
        XCTAssertEqual(m.imapFields().serverFlags?.rawFlagsAsShort(), cwFlags.rawFlagsAsShort())

        // Conflict: User has unset .recent, but that comes as set from the server.
        m.imapFields().localFlags?.reset()
        m.imapFields().serverFlags?.reset()
        cwFlags.removeAll()
        cwFlags.add(.recent)
        cwFlags.add(.flagged)
        m.imapFields().serverFlags?.flagRecent = true
        m.updateFromServer(cwFlags: cwFlags, context: moc)
        XCTAssertTrue(m.imapFields().localFlags?.flagRecent ?? false)
        XCTAssertTrue(m.imapFields().localFlags?.flagFlagged ?? false)
        XCTAssertEqual(m.imapFields().serverFlags?.rawFlagsAsShort(), cwFlags.rawFlagsAsShort())
    }

    // MARK: - HELPER

    func createCdMessageForFlags() -> CdMessage {
        let m = CdMessage(context: moc)
        let imap = CdImapFields(context: moc)
        let serverFlags = CdImapFlags(context: moc)
        let localFlags = CdImapFlags(context: moc)
        m.imap = imap
        imap.localFlags = localFlags
        imap.serverFlags = serverFlags

        XCTAssertEqual(localFlags.rawFlagsAsShort(), serverFlags.rawFlagsAsShort())
        XCTAssertFalse(localFlags.flagAnswered)
        XCTAssertFalse(localFlags.flagSeen)
        XCTAssertFalse(localFlags.flagDraft)
        XCTAssertFalse(localFlags.flagRecent)
        XCTAssertFalse(localFlags.flagDeleted)
        XCTAssertFalse(localFlags.flagFlagged)

        return m
    }

    func setAllCurrentImapFlags(of message: CdMessage, to isEnabled: Bool) {
        guard let imap = message.imap else {
            XCTFail()
            return
        }

        guard let flags = imap.localFlags else {
            XCTFail()
            return
        }

        flags.flagAnswered = isEnabled
        flags.flagDeleted = isEnabled
        flags.flagSeen = isEnabled
        flags.flagRecent = isEnabled
        flags.flagFlagged = isEnabled
        flags.flagDraft = isEnabled
    }
}

extension CdImapFlags {

    public func reset() {
        flagAnswered = false
        flagDraft = false
        flagFlagged = false
        flagRecent = false
        flagSeen = false
        flagDeleted = false
    }
}
