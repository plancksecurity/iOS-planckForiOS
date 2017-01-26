//
//  ImapFlagsTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/01/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import MessageModel

class ImapFlagsTests: XCTestCase {
    
    override func setUp() {
    }
    
    override func tearDown() {
    }

    func loopAllFlags(
        cdFields: CdImapFields, cwFlags: CWFlags, value: Bool) {
        var imapFlags = Message.ImapFlags()

        imapFlags.answered = cdFields.flagAnswered
        imapFlags.draft = cdFields.flagDraft
        imapFlags.flagged = cdFields.flagFlagged
        imapFlags.recent = cdFields.flagRecent
        imapFlags.seen = cdFields.flagSeen
        imapFlags.deleted = cdFields.flagDeleted

        for pflag in [
            PantomimeFlag.answered, PantomimeFlag.draft, PantomimeFlag.flagged,
            PantomimeFlag.recent, PantomimeFlag.seen, PantomimeFlag.deleted] {
                switch pflag {
                case .answered:
                    cdFields.flagAnswered = value
                    imapFlags.answered = value
                case .draft:
                    cdFields.flagDraft = value
                    imapFlags.draft = value
                case .flagged:
                    cdFields.flagFlagged = value
                    imapFlags.flagged = value
                case .recent:
                    cdFields.flagRecent = value
                    imapFlags.recent = value
                case .seen:
                    cdFields.flagSeen = value
                    imapFlags.seen = value
                case .deleted:
                    cdFields.flagDeleted = value
                    imapFlags.deleted = value
                }
                if value {
                    cwFlags.add(pflag)
                } else {
                    cwFlags.remove(pflag)
                }
                XCTAssertEqual(cwFlags.rawFlagsAsShort(), cdFields.rawFlagsAsShort())
                XCTAssertEqual(cwFlags.rawFlagsAsShort(), imapFlags.rawFlagsAsShort())
        }
    }
    
    func testCdImapFields() {
        let ps = PersistentSetup()
        ps.dummyToAvoidCompilerWarning()

        let cdFields = CdImapFields.create()
        let cwFlags = CWFlags()

        XCTAssertEqual(cwFlags.rawFlagsAsShort(), cdFields.rawFlagsAsShort())

        loopAllFlags(cdFields: cdFields, cwFlags: cwFlags, value: true)
        loopAllFlags(cdFields: cdFields, cwFlags: cwFlags, value: false)
    }
}
