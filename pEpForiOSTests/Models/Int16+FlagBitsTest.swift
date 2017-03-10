//
//  Int16+FlagBitsTest.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 09/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

class Int16_FlagBitsTest: XCTestCase {
    
    func testFlagBitIsSet_allSet() {
        let allSet = Int16.imapAllFlagsSet()
        XCTAssertTrue((allSet & ImapFlagBit.answered.rawValue) > 0, "bit is set")
        XCTAssertTrue((allSet & ImapFlagBit.deleted.rawValue) > 0, "bit is set")
        XCTAssertTrue((allSet & ImapFlagBit.draft.rawValue) > 0, "bit is set")
        XCTAssertTrue((allSet & ImapFlagBit.flagged.rawValue) > 0, "bit is set")
        XCTAssertTrue((allSet & ImapFlagBit.recent.rawValue) > 0, "bit is set")
        XCTAssertTrue((allSet & ImapFlagBit.seen.rawValue) > 0, "bit is set")
    }

    func testFlagBitIsSet_positiv_seenNotSet() {
        let seenNotSet = Int16(0) + ImapFlagBit.answered.rawValue + ImapFlagBit.deleted.rawValue
            + ImapFlagBit.draft.rawValue + ImapFlagBit.flagged.rawValue + ImapFlagBit.recent.rawValue
        XCTAssertTrue((seenNotSet & ImapFlagBit.answered.rawValue) > 0, "bit is set")
        XCTAssertTrue((seenNotSet & ImapFlagBit.deleted.rawValue) > 0, "bit is set")
        XCTAssertTrue((seenNotSet & ImapFlagBit.draft.rawValue) > 0, "bit is set")
        XCTAssertTrue((seenNotSet & ImapFlagBit.flagged.rawValue) > 0, "bit is set")
        XCTAssertTrue((seenNotSet & ImapFlagBit.recent.rawValue) > 0, "bit is set")
        XCTAssertFalse((seenNotSet & ImapFlagBit.seen.rawValue) > 0, "bit is not set")
    }
    func testFlagBitIsSet_positiv_recentNotSet() {
        let recentNotSet = Int16(0) + ImapFlagBit.answered.rawValue + ImapFlagBit.deleted.rawValue
            + ImapFlagBit.draft.rawValue + ImapFlagBit.flagged.rawValue + ImapFlagBit.seen.rawValue
        XCTAssertTrue((recentNotSet & ImapFlagBit.answered.rawValue) > 0, "bit is set")
        XCTAssertTrue((recentNotSet & ImapFlagBit.deleted.rawValue) > 0, "bit is set")
        XCTAssertTrue((recentNotSet & ImapFlagBit.draft.rawValue) > 0, "bit is set")
        XCTAssertTrue((recentNotSet & ImapFlagBit.flagged.rawValue) > 0, "bit is set")
        XCTAssertFalse((recentNotSet & ImapFlagBit.recent.rawValue) > 0, "bit is not set")
        XCTAssertTrue((recentNotSet & ImapFlagBit.seen.rawValue) > 0, "bit is set")
    }

    func testFlagBitIsSet_positiv_flaggedNotSet() {
        let flaggedNotSet = Int16(0) + ImapFlagBit.answered.rawValue + ImapFlagBit.deleted.rawValue
            + ImapFlagBit.draft.rawValue + ImapFlagBit.recent.rawValue
            + ImapFlagBit.seen.rawValue
        XCTAssertTrue((flaggedNotSet & ImapFlagBit.answered.rawValue) > 0, "bit is set")
        XCTAssertTrue((flaggedNotSet & ImapFlagBit.deleted.rawValue) > 0, "bit is set")
        XCTAssertTrue((flaggedNotSet & ImapFlagBit.draft.rawValue) > 0, "bit is set")
        XCTAssertFalse((flaggedNotSet & ImapFlagBit.flagged.rawValue) > 0, "bit is not set")
        XCTAssertTrue((flaggedNotSet & ImapFlagBit.recent.rawValue) > 0, "bit is set")
        XCTAssertTrue((flaggedNotSet & ImapFlagBit.seen.rawValue) > 0, "bit is set")
    }

    func testFlagBitIsSet_positiv_draftNotSet() {
        let draftNotSet = Int16(0) + ImapFlagBit.answered.rawValue + ImapFlagBit.deleted.rawValue
            + ImapFlagBit.flagged.rawValue + ImapFlagBit.recent.rawValue + ImapFlagBit.seen.rawValue
        XCTAssertTrue((draftNotSet & ImapFlagBit.answered.rawValue) > 0, "bit is set")
        XCTAssertTrue((draftNotSet & ImapFlagBit.deleted.rawValue) > 0, "bit is set")
        XCTAssertFalse((draftNotSet & ImapFlagBit.draft.rawValue) > 0, "bit is set")
        XCTAssertTrue((draftNotSet & ImapFlagBit.flagged.rawValue) > 0, "bit is set")
        XCTAssertTrue((draftNotSet & ImapFlagBit.recent.rawValue) > 0, "bit is set")
        XCTAssertTrue((draftNotSet & ImapFlagBit.seen.rawValue) > 0, "bit is set")
    }

    func testFlagBitIsSet_positiv_deletedNotSet() {
        let deletedNotSet = Int16(0) + ImapFlagBit.answered.rawValue + ImapFlagBit.draft.rawValue
            + ImapFlagBit.flagged.rawValue + ImapFlagBit.recent.rawValue + ImapFlagBit.seen.rawValue
        XCTAssertTrue((deletedNotSet & ImapFlagBit.answered.rawValue) > 0, "bit is set")
        XCTAssertFalse((deletedNotSet & ImapFlagBit.deleted.rawValue) > 0, "bit is not set")
        XCTAssertTrue((deletedNotSet & ImapFlagBit.draft.rawValue) > 0, "bit is set")
        XCTAssertTrue((deletedNotSet & ImapFlagBit.flagged.rawValue) > 0, "bit is set")
        XCTAssertTrue((deletedNotSet & ImapFlagBit.recent.rawValue) > 0, "bit is set")
        XCTAssertTrue((deletedNotSet & ImapFlagBit.seen.rawValue) > 0, "bit is set")
    }

    func testFlagBitIsSet_positiv_answeredNotSet() {
        let answeredNotSet = Int16(0) + ImapFlagBit.deleted.rawValue + ImapFlagBit.draft.rawValue
            + ImapFlagBit.flagged.rawValue + ImapFlagBit.recent.rawValue + ImapFlagBit.seen.rawValue
        XCTAssertFalse((answeredNotSet & ImapFlagBit.answered.rawValue) > 0, "bit is not set")
        XCTAssertTrue((answeredNotSet & ImapFlagBit.deleted.rawValue) > 0, "bit is set")
        XCTAssertTrue((answeredNotSet & ImapFlagBit.draft.rawValue) > 0, "bit is set")
        XCTAssertTrue((answeredNotSet & ImapFlagBit.flagged.rawValue) > 0, "bit is set")
        XCTAssertTrue((answeredNotSet & ImapFlagBit.recent.rawValue) > 0, "bit is set")
        XCTAssertTrue((answeredNotSet & ImapFlagBit.seen.rawValue) > 0, "bit is set")
    }
}
