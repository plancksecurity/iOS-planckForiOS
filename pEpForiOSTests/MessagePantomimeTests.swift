//
//  MessagePantomimeTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import MessageModel

class MessagePantomimeTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()
    }

    func testPantomimeFlagsFromMessage() {
        let m = CdMessage.create()
        m.imap = CdImapFields.createWithDefaults()

        m.imap?.flagFlagged = true
        m.updateFlags()

        for f: PantomimeFlag in [.answered, .deleted, .draft, .recent, .seen] {
            XCTAssertFalse(m.pantomimeFlags().contain(f))
        }
        XCTAssertTrue(m.pantomimeFlags().contain(.flagged))

        m.imap?.flagAnswered = true
        XCTAssertFalse(m.pantomimeFlags().contain(.answered))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.answered))

        m.imap?.flagDeleted = true
        XCTAssertFalse(m.pantomimeFlags().contain(.deleted))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.deleted))

        m.imap?.flagRecent = true
        XCTAssertFalse(m.pantomimeFlags().contain(.recent))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.recent))

        m.imap?.flagDraft = true
        XCTAssertFalse(m.pantomimeFlags().contain(.draft))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.draft))

        m.imap?.flagSeen = true
        XCTAssertFalse(m.pantomimeFlags().contain(.seen))
        m.updateFlags()
        XCTAssertTrue(m.pantomimeFlags().contain(.seen))
    }

    func testCWFlagsAsShort() {
        let fl = CWFlags.init()
        fl.add(.recent)
        XCTAssertEqual(fl.rawFlagsAsShort(), 8)

        fl.add(.answered)
        XCTAssertEqual(fl.rawFlagsAsShort(), 9)

        fl.add(.deleted)
        XCTAssertEqual(fl.rawFlagsAsShort(), 41)

        fl.add(.seen)
        XCTAssertEqual(fl.rawFlagsAsShort(), 57)
    }

    func testUpdateFlags() {
        let m = CdMessage.create()
        m.imap = CdImapFields.createWithDefaults()

        XCTAssertEqual(m.imap?.flagsFromServer, 0)

        var valuesSoFar: Int16 = 0
        for fl in [PantomimeFlag.answered, .draft, .flagged, .recent, .seen, .deleted] {
            switch fl {
            case .answered:
                m.imap?.flagAnswered = true
            case .draft:
                m.imap?.flagDraft = true
            case .flagged:
                m.imap?.flagFlagged = true
            case .recent:
                m.imap?.flagRecent = true
            case .seen:
                m.imap?.flagSeen = true
            case .deleted:
                m.imap?.flagDeleted = true
            }
            valuesSoFar += Int(fl.rawValue)
            m.updateFlags()
            XCTAssertEqual(m.imap?.flagsCurrent, valuesSoFar)
        }
    }

    func testStoreCommandForUpdate() {
        let m = CdMessage.create()
        m.imap = CdImapFields.createWithDefaults()

        m.uid = 1024
        m.imap?.flagsFromServer = 0
        m.imap?.flagDeleted = true
        m.updateFlags()
        XCTAssertEqual(m.storeCommandForUpdate()?.0,
                       "UID STORE 1024 FLAGS.SILENT (\\Deleted)")

        // Check if 'difference' is taken into account
        m.imap?.flagsFromServer = CWFlags(flags: PantomimeFlag.deleted).rawFlagsAsShort()
        m.updateFlags()
        XCTAssertEqual(m.storeCommandForUpdate()?.0,
                       "UID STORE 1024 FLAGS.SILENT (\\Deleted)")

        m.imap?.flagAnswered = true
        m.updateFlags()
        XCTAssertEqual(m.storeCommandForUpdate()?.0,
                       "UID STORE 1024 FLAGS.SILENT (\\Answered \\Deleted)")

        m.imap?.flagSeen = true
        m.updateFlags()
        XCTAssertEqual(m.storeCommandForUpdate()?.0,
                       "UID STORE 1024 FLAGS.SILENT (\\Answered \\Seen \\Deleted)")

        m.imap?.flagFlagged = true
        m.updateFlags()
        XCTAssertEqual(
            m.storeCommandForUpdate()?.0,
            "UID STORE 1024 FLAGS.SILENT (\\Answered \\Flagged \\Seen \\Deleted)")
    }
}
