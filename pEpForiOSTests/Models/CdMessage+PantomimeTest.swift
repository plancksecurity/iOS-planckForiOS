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

    func testStoreCommandForFlagsToRemoved() {
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
                       "UID STORE 1024 -FLAGS.SILENT (\\Answered \\Draft \\Flagged \\Seen \\Deleted)")
    }

    func testStoreCommandForFlagsToAdd() {
        let m = CdMessage.create()
        m.imap = CdImapFields.create()

        m.uid = 1024
        m.imap?.flagsFromServer = Int16(0)
        setAllCurrentImapFlags(of: m, to: false)

        // nothing has changed
        XCTAssertNil(m.storeCommandForFlagsToRemove()?.0)

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
        XCTAssertEqual(m.storeCommandForFlagsToAdd()!.0,
                       "UID STORE 1024 +FLAGS.SILENT (\\Answered \\Draft \\Flagged \\Seen \\Deleted)")
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
