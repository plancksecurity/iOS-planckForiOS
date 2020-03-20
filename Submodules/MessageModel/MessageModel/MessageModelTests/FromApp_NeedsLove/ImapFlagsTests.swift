//
//  ImapFlagsTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/01/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
import PantomimeFramework

class ImapFlagsTests: PersistentStoreDrivenTestBase {

    func testCdImapFields() {
        let cdFlags = CdImapFlags(context: moc)
        let cwFlags = CWFlags()

        XCTAssertEqual(cwFlags.rawFlagsAsShort(), cdFlags.rawFlagsAsShort())

        loopAllFlags(cdFlags: cdFlags, cwFlags: cwFlags, value: true)
        loopAllFlags(cdFlags: cdFlags, cwFlags: cwFlags, value: false)
    }
}

// MARK: - HELPER

extension ImapFlagsTests {

    func loopAllFlags(cdFlags: CdImapFlags, cwFlags: CWFlags, value: Bool) {
        let imapFlags = ImapFlags(cdObject: cdFlags, context: moc)

        imapFlags.answered = cdFlags.flagAnswered
        imapFlags.draft = cdFlags.flagDraft
        imapFlags.flagged = cdFlags.flagFlagged
        imapFlags.recent = cdFlags.flagRecent
        imapFlags.seen = cdFlags.flagSeen
        imapFlags.deleted = cdFlags.flagDeleted

        for pflag in [
            PantomimeFlag.answered, PantomimeFlag.draft, PantomimeFlag.flagged,
            PantomimeFlag.recent, PantomimeFlag.seen, PantomimeFlag.deleted] {
                switch pflag {
                case .answered:
                    cdFlags.flagAnswered = value
                    imapFlags.answered = value
                case .draft:
                    cdFlags.flagDraft = value
                    imapFlags.draft = value
                case .flagged:
                    cdFlags.flagFlagged = value
                    imapFlags.flagged = value
                case .recent:
                    cdFlags.flagRecent = value
                    imapFlags.recent = value
                case .seen:
                    cdFlags.flagSeen = value
                    imapFlags.seen = value
                case .deleted:
                    cdFlags.flagDeleted = value
                    imapFlags.deleted = value
                @unknown default:
                    XCTFail("unhandled case")
                }
                if value {
                    cwFlags.add(pflag)
                } else {
                    cwFlags.remove(pflag)
                }
                XCTAssertEqual(cwFlags.rawFlagsAsShort(), cdFlags.rawFlagsAsShort())
                XCTAssertEqual(cwFlags.rawFlagsAsShort(), imapFlags.rawFlagsAsShort())
        }
    }
}
