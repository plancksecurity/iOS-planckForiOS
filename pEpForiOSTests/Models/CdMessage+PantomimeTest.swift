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

    func testStoreCommandForFlagsToRemoved_allServerFlagsSet() {
        let m = CdMessage.create()
        m.imap = CdImapFields.create()

        m.uid = 1024
        m.imap?.flagsFromServer = Int16.imapAllFlagsSet()
        setAllCurrentImapFlags(of: m, to: true)

        // nothing has changed
        XCTAssertNil(m.storeCommandForFlagsToRemove()?.0)

        // remove flags locally (while offline) and assure it's handled correctly
        m.imap?.flagAnswered = false
        XCTAssertEqual(m.storeCommandForFlagsToRemove()!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered)")

        m.imap?.flagDraft = false
        XCTAssertEqual(m.storeCommandForFlagsToRemove()!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft)")

        m.imap?.flagFlagged = false
        XCTAssertEqual(m.storeCommandForFlagsToRemove()!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        m.imap?.flagSeen = false
        XCTAssertEqual(m.storeCommandForFlagsToRemove()!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft \\Flagged \\Seen)")

        m.imap?.flagDeleted = false
        XCTAssertEqual(m.storeCommandForFlagsToRemove()!.0,
                       "UID STORE 1024 -FLAGS.SILENT " +
                        "(\\Answered \\Draft \\Flagged \\Seen \\Deleted)")
    }

    func testStoreCommandForFlagsToRemove_someServerFlagsSet() {
        let m = CdMessage.create()
        m.imap = CdImapFields.create()

        m.uid = 1024
        m.imap?.flagsFromServer = Int16.imapAllFlagsSet()
        m.imap?.flagsFromServer.imapUnSetFlagBit(.seen) // seen not set on server ...
        setAllCurrentImapFlags(of: m, to: true)

        // ... so it should not be removed

        // nothing has changed
        XCTAssertNil(m.storeCommandForFlagsToRemove()?.0)

        // remove flags locally (while offline) and assure it's handled correctly
        m.imap?.flagAnswered = false
        XCTAssertEqual(m.storeCommandForFlagsToRemove()!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered)")

        m.imap?.flagDraft = false
        XCTAssertEqual(m.storeCommandForFlagsToRemove()!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft)")

        m.imap?.flagFlagged = false
        XCTAssertEqual(m.storeCommandForFlagsToRemove()!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        m.imap?.flagSeen = false
        XCTAssertEqual(m.storeCommandForFlagsToRemove()!.0,
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        m.imap?.flagDeleted = false
        XCTAssertEqual(m.storeCommandForFlagsToRemove()!.0,
                       "UID STORE 1024 -FLAGS.SILENT " + "(\\Answered \\Draft \\Flagged \\Deleted)")
    }

    func testStoreCommandForFlagsToAdd_noServerFlagsSet() {
        let m = CdMessage.create()
        m.imap = CdImapFields.create()

        m.uid = 1024
        m.imap?.flagsFromServer = Int16.imapNoFlagsSet()
        setAllCurrentImapFlags(of: m, to: false)

        // nothing has changed
        XCTAssertNil(m.storeCommandForFlagsToAdd()?.0)

        // add flags locally (while offline) and assure it's handled correctly
        m.imap?.flagAnswered = true
        XCTAssertEqual(m.storeCommandForFlagsToAdd()!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered)")

        m.imap?.flagDraft = true
        XCTAssertEqual(m.storeCommandForFlagsToAdd()!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft)")

        m.imap?.flagFlagged = true
        XCTAssertEqual(m.storeCommandForFlagsToAdd()!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        m.imap?.flagSeen = true
        XCTAssertEqual(m.storeCommandForFlagsToAdd()!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft \\Flagged \\Seen)")

        m.imap?.flagDeleted = true
        XCTAssertEqual(m.storeCommandForFlagsToAdd()!.0, "UID STORE 1024 +FLAGS.SILENT " +
            "(\\Answered \\Draft \\Flagged \\Seen \\Deleted)")
    }

    func testStoreCommandForFlagsToAdd_someSeverFlagsSet() {
        let m = CdMessage.create()
        m.imap = CdImapFields.create()

        m.uid = 1024
        m.imap?.flagsFromServer = Int16.imapNoFlagsSet()
        m.imap?.flagsFromServer.imapSetFlagBit(.seen) // flagSeen is set on server ...
        setAllCurrentImapFlags(of: m, to: false)

        // ... so //Seen must not be added

        // nothing has changed
        XCTAssertNil(m.storeCommandForFlagsToAdd()?.0)

        // add flags locally (while offline) and assure it's handled correctly
        m.imap?.flagAnswered = true
        XCTAssertEqual(m.storeCommandForFlagsToAdd()!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered)")

        m.imap?.flagDraft = true
        XCTAssertEqual(m.storeCommandForFlagsToAdd()!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft)")

        m.imap?.flagFlagged = true
        XCTAssertEqual(m.storeCommandForFlagsToAdd()!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        m.imap?.flagSeen = true
        XCTAssertEqual(m.storeCommandForFlagsToAdd()!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft \\Flagged)")

        m.imap?.flagDeleted = true
        XCTAssertEqual(m.storeCommandForFlagsToAdd()!.0, "UID STORE 1024 +FLAGS.SILENT " +
            "(\\Answered \\Draft \\Flagged \\Deleted)")
    }

    //MARK: - HELPER

    func setAllCurrentImapFlags(of message: CdMessage, to isEnabled: Bool) {
        guard let imap = message.imap else {
            XCTFail()
            return
        }

        if isEnabled  {
            imap.flagsCurrent = Int16.imapAllFlagsSet()
        } else {
            imap.flagsCurrent = Int16.imapNoFlagsSet()
        }

        imap.flagAnswered = isEnabled
        imap.flagDeleted = isEnabled
        imap.flagSeen = isEnabled
        imap.flagRecent = isEnabled
        imap.flagFlagged = isEnabled
        imap.flagDraft = isEnabled
    }
}
