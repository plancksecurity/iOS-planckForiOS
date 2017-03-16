//
//  CdMessage+PantomimeTest.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 10/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

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

        m.uid = 1024
        m.imap?.flagsFromServer = ImapFlagsBits.imapAllFlagsSet()
        m.imap?.flagsFromServer.imapUnSetFlagBit(.seen) // seen not set on server ...
        setAllCurrentImapFlags(of: m, to: true)

        // ... so it should not be removed

        // nothing has changed
        XCTAssertNil(m.storeCommandForUpdateFlags(to: .remove)?.0)

        // remove flags locally (while offline) and assure it's handled correctly
        m.imap?.flagAnswered = false

        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .remove)!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered)")

        m.imap?.flagDraft = false
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .remove)!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft)")

        m.imap?.flagFlagged = false
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .remove)!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        m.imap?.flagSeen = false
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .remove)!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        m.imap?.flagDeleted = false
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .remove)!.0,
                       "UID STORE 1024 -FLAGS.SILENT " + "(\\Answered \\Draft \\Flagged \\Deleted)")
    }

    func testStoreCommandForFlagsToAdd_noServerFlagsSet() {
        let m = CdMessage.create()
        m.imap = CdImapFields.create()

        m.uid = 1024
        m.imap?.flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
        setAllCurrentImapFlags(of: m, to: false)

        // nothing has changed
        XCTAssertNil(m.storeCommandForUpdateFlags(to: .add)?.0)

        // add flags locally (while offline) and assure it's handled correctly
        m.imap?.flagAnswered = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered)")

        m.imap?.flagDraft = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft)")

        m.imap?.flagFlagged = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        m.imap?.flagSeen = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft \\Flagged \\Seen)")

        m.imap?.flagDeleted = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0, "UID STORE 1024 +FLAGS.SILENT " +
            "(\\Answered \\Draft \\Flagged \\Seen \\Deleted)")
    }

    func testStoreCommandForFlagsToAdd_someSeverFlagsSet() {
        let m = CdMessage.create()
        m.imap = CdImapFields.create()

        m.uid = 1024
        m.imap?.flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
        m.imap?.flagsFromServer.imapSetFlagBit(.seen) // flagSeen is set on server ...
        setAllCurrentImapFlags(of: m, to: false)

        // ... so //Seen must not be added

        // nothing has changed
        XCTAssertNil(m.storeCommandForUpdateFlags(to: .add)?.0)

        // add flags locally (while offline) and assure it's handled correctly
        m.imap?.flagAnswered = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered)")

        m.imap?.flagDraft = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft)")

        m.imap?.flagFlagged = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        m.imap?.flagSeen = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        m.imap?.flagDeleted = true
        XCTAssertEqual(m.storeCommandForUpdateFlags(to: .add)!.0, "UID STORE 1024 +FLAGS.SILENT " +
            "(\\Answered \\Draft \\Flagged \\Deleted)")
    }

    //MARK: - HELPER

    func setAllCurrentImapFlags(of message: CdMessage, to isEnabled: Bool) {
        guard let imap = message.imap else {
            XCTFail()
            return
        }

        imap.flagAnswered = isEnabled
        imap.flagDeleted = isEnabled
        imap.flagSeen = isEnabled
        imap.flagRecent = isEnabled
        imap.flagFlagged = isEnabled
        imap.flagDraft = isEnabled
    }
}
