//
//  CdMessage+PantomimeTest.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 10/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import MessageModel

class CdMessage_PantomimeTest: XCTestCase {
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()
    }

    //MARK: - StoreCommandForFlagsToRemoved / Add

    func testStoreCommandForFlagsToRemove_someServerFlagsSet() {
        let m = CdMessage.create()
        m.imap = CdImapFields.create()

        let localFlags = CdImapFlags.create()
        m.imap?.localFlags = localFlags

        let serverFlags = CdImapFlags.create()
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
                       "UID STORE 1024 -FLAGS.SILENT " + "(\\Answered \\Draft \\Flagged \\Deleted)")
    }

    func testStoreCommandForFlagsToAdd_noServerFlagsSet() {
        let m = CdMessage.create()
        m.imap = CdImapFields.create()

        let localFlags = CdImapFlags.create()
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
        let m = CdMessage.create()
        m.imap = CdImapFields.create()

        let localFlags = CdImapFlags.create()
        m.imap?.localFlags = localFlags

        let serverFlags = CdImapFlags.create()
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
        let cdAccount = TestData().createWorkingCdAccount()

        let folder = CdFolder.create()
        folder.account = cdAccount
        folder.name = ImapSync.defaultImapInboxName
        folder.uuid = MessageID.generate()

        guard let data = TestUtil.loadDataWithFileName("UnencryptedHTMLMail.txt") else {
            XCTAssertTrue(false)
            return
        }
        let message = CWIMAPMessage.init(data: data)
        message.setFolder(CWIMAPFolder.init(name: ImapSync.defaultImapInboxName))
        let msg = CdMessage.insertOrUpdate(
            pantomimeMessage: message, account: cdAccount, messageUpdate: CWMessageUpdate(),
            forceParseAttachments: true)
        XCTAssertNotNil(msg)
        if let m = msg {
            XCTAssertNotNil(m.longMessage)
            XCTAssertNotNil(m.longMessageFormatted)
        }
    }

    //MARK: - HELPER

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
