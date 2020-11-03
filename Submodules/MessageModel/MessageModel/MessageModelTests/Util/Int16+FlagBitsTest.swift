//
//  Int16+FlagBitsTest.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 09/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel

class Int16_FlagBitsTest: XCTestCase {

    // MARK: - imapFlagBitIsSet

    func testFlagBitIsSet_allSet() {
        let allSet = ImapFlagsBits.imapAllFlagsSet()
        XCTAssertTrue((allSet & ImapFlagBit.answered.rawValue) > 0, "bit is set")
        XCTAssertTrue((allSet & ImapFlagBit.deleted.rawValue) > 0, "bit is set")
        XCTAssertTrue((allSet & ImapFlagBit.draft.rawValue) > 0, "bit is set")
        XCTAssertTrue((allSet & ImapFlagBit.flagged.rawValue) > 0, "bit is set")
        XCTAssertTrue((allSet & ImapFlagBit.recent.rawValue) > 0, "bit is set")
        XCTAssertTrue((allSet & ImapFlagBit.seen.rawValue) > 0, "bit is set")

        XCTAssertTrue(allSet.imapFlagBitIsSet(flagbit: .answered), "bit is set")
        XCTAssertTrue(allSet.imapFlagBitIsSet(flagbit: .draft), "bit is set")
        XCTAssertTrue(allSet.imapFlagBitIsSet(flagbit: .flagged), "bit is set")
        XCTAssertTrue(allSet.imapFlagBitIsSet(flagbit: .recent), "bit is set")
        XCTAssertTrue(allSet.imapFlagBitIsSet(flagbit: .seen), "bit is set")
        XCTAssertTrue(allSet.imapFlagBitIsSet(flagbit: .deleted), "bit is set")
    }

    func testFlagBitIsSet_positiv_seenNotSet() {
        let seenNotSet = Int16(0) + ImapFlagBit.answered.rawValue + ImapFlagBit.deleted.rawValue
            + ImapFlagBit.draft.rawValue + ImapFlagBit.flagged.rawValue
            + ImapFlagBit.recent.rawValue
        XCTAssertTrue((seenNotSet & ImapFlagBit.answered.rawValue) > 0, "bit is set")
        XCTAssertTrue((seenNotSet & ImapFlagBit.deleted.rawValue) > 0, "bit is set")
        XCTAssertTrue((seenNotSet & ImapFlagBit.draft.rawValue) > 0, "bit is set")
        XCTAssertTrue((seenNotSet & ImapFlagBit.flagged.rawValue) > 0, "bit is set")
        XCTAssertTrue((seenNotSet & ImapFlagBit.recent.rawValue) > 0, "bit is set")
        XCTAssertFalse((seenNotSet & ImapFlagBit.seen.rawValue) > 0, "bit is not set")

        XCTAssertTrue(seenNotSet.imapFlagBitIsSet(flagbit: .answered), "bit is set")
        XCTAssertTrue(seenNotSet.imapFlagBitIsSet(flagbit: .draft), "bit is set")
        XCTAssertTrue(seenNotSet.imapFlagBitIsSet(flagbit: .flagged), "bit is set")
        XCTAssertTrue(seenNotSet.imapFlagBitIsSet(flagbit: .recent), "bit is set")
        XCTAssertFalse(seenNotSet.imapFlagBitIsSet(flagbit: .seen), "bit is not set")
        XCTAssertTrue(seenNotSet.imapFlagBitIsSet(flagbit: .deleted), "bit is set")
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

        XCTAssertTrue(recentNotSet.imapFlagBitIsSet(flagbit: .answered), "bit is set")
        XCTAssertTrue(recentNotSet.imapFlagBitIsSet(flagbit: .draft), "bit is set")
        XCTAssertTrue(recentNotSet.imapFlagBitIsSet(flagbit: .flagged), "bit is set")
        XCTAssertFalse(recentNotSet.imapFlagBitIsSet(flagbit: .recent), "bit is not set")
        XCTAssertTrue(recentNotSet.imapFlagBitIsSet(flagbit: .seen), "bit is set")
        XCTAssertTrue(recentNotSet.imapFlagBitIsSet(flagbit: .deleted), "bit is set")
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

        XCTAssertTrue(flaggedNotSet.imapFlagBitIsSet(flagbit: .answered), "bit is set")
        XCTAssertTrue(flaggedNotSet.imapFlagBitIsSet(flagbit: .draft), "bit is set")
        XCTAssertFalse(flaggedNotSet.imapFlagBitIsSet(flagbit: .flagged), "bit is not set")
        XCTAssertTrue(flaggedNotSet.imapFlagBitIsSet(flagbit: .recent), "bit is set")
        XCTAssertTrue(flaggedNotSet.imapFlagBitIsSet(flagbit: .seen), "bit is set")
        XCTAssertTrue(flaggedNotSet.imapFlagBitIsSet(flagbit: .deleted), "bit is set")
    }

    func testFlagBitIsSet_positiv_draftNotSet() {
        let draftNotSet = Int16(0) + ImapFlagBit.answered.rawValue + ImapFlagBit.deleted.rawValue
            + ImapFlagBit.flagged.rawValue + ImapFlagBit.recent.rawValue + ImapFlagBit.seen.rawValue
        XCTAssertTrue((draftNotSet & ImapFlagBit.answered.rawValue) > 0, "bit is set")
        XCTAssertTrue((draftNotSet & ImapFlagBit.deleted.rawValue) > 0, "bit is set")
        XCTAssertFalse((draftNotSet & ImapFlagBit.draft.rawValue) > 0, "bit is not set")
        XCTAssertTrue((draftNotSet & ImapFlagBit.flagged.rawValue) > 0, "bit is set")
        XCTAssertTrue((draftNotSet & ImapFlagBit.recent.rawValue) > 0, "bit is set")
        XCTAssertTrue((draftNotSet & ImapFlagBit.seen.rawValue) > 0, "bit is set")

        XCTAssertTrue(draftNotSet.imapFlagBitIsSet(flagbit: .answered), "bit is set")
        XCTAssertFalse(draftNotSet.imapFlagBitIsSet(flagbit: .draft), "bit is set")
        XCTAssertTrue(draftNotSet.imapFlagBitIsSet(flagbit: .flagged), "bit is set")
        XCTAssertTrue(draftNotSet.imapFlagBitIsSet(flagbit: .recent), "bit is not set")
        XCTAssertTrue(draftNotSet.imapFlagBitIsSet(flagbit: .seen), "bit is set")
        XCTAssertTrue(draftNotSet.imapFlagBitIsSet(flagbit: .deleted), "bit is set")
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

        XCTAssertTrue(deletedNotSet.imapFlagBitIsSet(flagbit: .answered), "bit is set")
        XCTAssertTrue(deletedNotSet.imapFlagBitIsSet(flagbit: .draft), "bit is set")
        XCTAssertTrue(deletedNotSet.imapFlagBitIsSet(flagbit: .flagged), "bit is set")
        XCTAssertTrue(deletedNotSet.imapFlagBitIsSet(flagbit: .recent), "bit is set")
        XCTAssertTrue(deletedNotSet.imapFlagBitIsSet(flagbit: .seen), "bit is set")
        XCTAssertFalse(deletedNotSet.imapFlagBitIsSet(flagbit: .deleted), "bit is not set")
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

        XCTAssertFalse(answeredNotSet.imapFlagBitIsSet(flagbit: .answered), "bit is not set")
        XCTAssertTrue(answeredNotSet.imapFlagBitIsSet(flagbit: .draft), "bit is set")
        XCTAssertTrue(answeredNotSet.imapFlagBitIsSet(flagbit: .flagged), "bit is set")
        XCTAssertTrue(answeredNotSet.imapFlagBitIsSet(flagbit: .recent), "bit is set")
        XCTAssertTrue(answeredNotSet.imapFlagBitIsSet(flagbit: .seen), "bit is set")
        XCTAssertTrue(answeredNotSet.imapFlagBitIsSet(flagbit: .deleted), "bit is set")
    }

    // MARK: - imapSetFlagBit

    func testImapSetFlagBit_noneSet() {
        var testee = Int16(0)
        testee.imapSetFlagBit(.answered)
        XCTAssertTrue((testee & ImapFlagBit.answered.rawValue) > 0, "bit is set")
        testee.imapSetFlagBit(.deleted)
        XCTAssertTrue((testee & ImapFlagBit.deleted.rawValue) > 0, "bit is set")
        testee.imapSetFlagBit(.draft)
        XCTAssertTrue((testee & ImapFlagBit.draft.rawValue) > 0, "bit is set")
        testee.imapSetFlagBit(.flagged)
        XCTAssertTrue((testee & ImapFlagBit.flagged.rawValue) > 0, "bit is set")
        testee.imapSetFlagBit(.recent)
        XCTAssertTrue((testee & ImapFlagBit.recent.rawValue) > 0, "bit is set")
        testee.imapSetFlagBit(.seen)
        XCTAssertTrue((testee & ImapFlagBit.seen.rawValue) > 0, "bit is set")
    }

    func testImapSetFlagBit_allSet() {
        var testee = ImapFlagsBits.imapAllFlagsSet()
        testee.imapSetFlagBit(.answered)
        XCTAssertTrue((testee & ImapFlagBit.answered.rawValue) > 0, "bit is set")
        testee.imapSetFlagBit(.deleted)
        XCTAssertTrue((testee & ImapFlagBit.deleted.rawValue) > 0, "bit is set")
        testee.imapSetFlagBit(.draft)
        XCTAssertTrue((testee & ImapFlagBit.draft.rawValue) > 0, "bit is set")
        testee.imapSetFlagBit(.flagged)
        XCTAssertTrue((testee & ImapFlagBit.flagged.rawValue) > 0, "bit is set")
        testee.imapSetFlagBit(.recent)
        XCTAssertTrue((testee & ImapFlagBit.recent.rawValue) > 0, "bit is set")
        testee.imapSetFlagBit(.seen)
        XCTAssertTrue((testee & ImapFlagBit.seen.rawValue) > 0, "bit is set")
    }

    // MARK: - imapUnSetFlagBit

    func testImapUnSetFlagBit_noneSet() {
        var testee = Int16(0)
        testee.imapUnSetFlagBit(.answered)
        XCTAssertFalse((testee & ImapFlagBit.answered.rawValue) > 0, "bit is not set")
        testee.imapUnSetFlagBit(.deleted)
        XCTAssertFalse((testee & ImapFlagBit.deleted.rawValue) > 0, "bit is not set")
        testee.imapUnSetFlagBit(.draft)
        XCTAssertFalse((testee & ImapFlagBit.draft.rawValue) > 0, "bit is not set")
        testee.imapUnSetFlagBit(.flagged)
        XCTAssertFalse((testee & ImapFlagBit.flagged.rawValue) > 0, "bit is not set")
        testee.imapUnSetFlagBit(.recent)
        XCTAssertFalse((testee & ImapFlagBit.recent.rawValue) > 0, "bit is not set")
        testee.imapUnSetFlagBit(.seen)
        XCTAssertFalse((testee & ImapFlagBit.seen.rawValue) > 0, "bit is not set")
    }

    func testImapUnSetFlagBit_allSet() {
        var testee = ImapFlagsBits.imapAllFlagsSet()
        testee.imapUnSetFlagBit(.answered)
        XCTAssertFalse((testee & ImapFlagBit.answered.rawValue) > 0, "bit is not set")
        testee.imapUnSetFlagBit(.deleted)
        XCTAssertFalse((testee & ImapFlagBit.deleted.rawValue) > 0, "bit is not set")
        testee.imapUnSetFlagBit(.draft)
        XCTAssertFalse((testee & ImapFlagBit.draft.rawValue) > 0, "bit is not set")
        testee.imapUnSetFlagBit(.flagged)
        XCTAssertFalse((testee & ImapFlagBit.flagged.rawValue) > 0, "bit is not set")
        testee.imapUnSetFlagBit(.recent)
        XCTAssertFalse((testee & ImapFlagBit.recent.rawValue) > 0, "bit is not set")
        testee.imapUnSetFlagBit(.seen)
        XCTAssertFalse((testee & ImapFlagBit.seen.rawValue) > 0, "bit is not set")
    }

    // MARK: - imapToggelFlagBit

    func testImapToggelFlagBit_allSet() {
        var testee = ImapFlagsBits.imapAllFlagsSet()
        testee.imapToggelFlagBit(.answered)
        XCTAssertFalse((testee & ImapFlagBit.answered.rawValue) > 0, "bit is not set")
        testee.imapToggelFlagBit(.deleted)
        XCTAssertFalse((testee & ImapFlagBit.deleted.rawValue) > 0, "bit is not set")
        testee.imapToggelFlagBit(.draft)
        XCTAssertFalse((testee & ImapFlagBit.draft.rawValue) > 0, "bit is not set")
        testee.imapToggelFlagBit(.flagged)
        XCTAssertFalse((testee & ImapFlagBit.flagged.rawValue) > 0, "bit is not set")
        testee.imapToggelFlagBit(.recent)
        XCTAssertFalse((testee & ImapFlagBit.recent.rawValue) > 0, "bit is not set")
        testee.imapToggelFlagBit(.seen)
        XCTAssertFalse((testee & ImapFlagBit.seen.rawValue) > 0, "bit is not set")
    }

    func testImapToggelFlagBit_noneSet() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        testee.imapToggelFlagBit(.answered)
        XCTAssertTrue((testee & ImapFlagBit.answered.rawValue) > 0, "bit is set")
        testee.imapToggelFlagBit(.deleted)
        XCTAssertTrue((testee & ImapFlagBit.deleted.rawValue) > 0, "bit is set")
        testee.imapToggelFlagBit(.draft)
        XCTAssertTrue((testee & ImapFlagBit.draft.rawValue) > 0, "bit is set")
        testee.imapToggelFlagBit(.flagged)
        XCTAssertTrue((testee & ImapFlagBit.flagged.rawValue) > 0, "bit is set")
        testee.imapToggelFlagBit(.recent)
        XCTAssertTrue((testee & ImapFlagBit.recent.rawValue) > 0, "bit is set")
        testee.imapToggelFlagBit(.seen)
        XCTAssertTrue((testee & ImapFlagBit.seen.rawValue) > 0, "bit is set")
    }

    // MARK: - imapAnyFlagIsSet

    func testImapAnyFlagIsSet_noneSet() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        XCTAssertFalse(testee.imapAnyFlagIsSet(), "no flag set")

        testee = ImapFlagsBits.imapNoFlagsSet()
        testee.imapSetFlagBit(.answered)
        XCTAssertTrue(testee.imapAnyFlagIsSet(), "a bit is set")

        testee = ImapFlagsBits.imapNoFlagsSet()
        testee.imapSetFlagBit(.draft)
        XCTAssertTrue(testee.imapAnyFlagIsSet(), "a bit is set")

        testee = ImapFlagsBits.imapNoFlagsSet()
        testee.imapSetFlagBit(.flagged)
        XCTAssertTrue(testee.imapAnyFlagIsSet(), "a bit is set")

        testee = ImapFlagsBits.imapNoFlagsSet()
        testee.imapSetFlagBit(.recent)
        XCTAssertTrue(testee.imapAnyFlagIsSet(), "a bit is set")

        testee = ImapFlagsBits.imapNoFlagsSet()
        testee.imapSetFlagBit(.seen)
        XCTAssertTrue(testee.imapAnyFlagIsSet(), "a bit is set")
    }

    // MARK: -  imapNoFlagSet is tested indirectly by imapAnyFlagIsSet

    // MARK: - imapAnyRelevantFlagSet

    func testImapAnyRelevantFlagSet() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        XCTAssertFalse(testee.imapAnyRelevantFlagSet(), "is relevant")

        testee = ImapFlagsBits.imapNoFlagsSet()
        testee.imapSetFlagBit(.answered)
        XCTAssertTrue(testee.imapAnyRelevantFlagSet(), "is relevant")

        testee = ImapFlagsBits.imapNoFlagsSet()
        testee.imapSetFlagBit(.draft)
        XCTAssertTrue(testee.imapAnyRelevantFlagSet(), "is relevant")

        testee = ImapFlagsBits.imapNoFlagsSet()
        testee.imapSetFlagBit(.flagged)
        XCTAssertTrue(testee.imapAnyRelevantFlagSet(), "is relevant")

        testee = ImapFlagsBits.imapNoFlagsSet()
        testee.imapSetFlagBit(.recent)
        XCTAssertFalse(testee.imapAnyRelevantFlagSet(), "is not relevant")

        testee = ImapFlagsBits.imapNoFlagsSet()
        testee.imapSetFlagBit(.seen)
        XCTAssertTrue(testee.imapAnyRelevantFlagSet(), "is relevant")
    }

    // MARK: -  imapNoRelevantFlagSet is tested indirectly by imapAnyRelevantFlagSet

    // MARK: - imapOnlyFlagBitSet

    //positive
    func testImapOnlyFlagBitSet_positive_anwered() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        // set exactly one bit
        testee += ImapFlagBit.answered.rawValue

        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .answered)
        XCTAssertTrue(isTheOnlyFlagSet, "it's the only bit set")
    }

    func testImapOnlyFlagBitSet_positive_draft() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        // set exactly one bit
        testee += ImapFlagBit.draft.rawValue

        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .draft)
        XCTAssertTrue(isTheOnlyFlagSet, "it's the only bit set")
    }

    func testImapOnlyFlagBitSet_positive_flagged() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        // set exactly one bit
        testee += ImapFlagBit.flagged.rawValue

        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .flagged)
        XCTAssertTrue(isTheOnlyFlagSet, "it's the only bit set")
    }

    func testImapOnlyFlagBitSet_positive_recent() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        // set exactly one bit
        testee += ImapFlagBit.recent.rawValue

        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .recent)
        XCTAssertTrue(isTheOnlyFlagSet, "it's the only bit set")
    }

    func testImapOnlyFlagBitSet_positive_seen() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        // set exactly one bit
        testee += ImapFlagBit.seen.rawValue

        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .seen)
        XCTAssertTrue(isTheOnlyFlagSet, "it's the only bit set")
    }

    func testImapOnlyFlagBitSet_positive_deleted() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        // set exactly one bit
        testee += ImapFlagBit.deleted.rawValue

        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .deleted)
        XCTAssertTrue(isTheOnlyFlagSet, "it's the only bit set")
    }

    //negative

    func testImapOnlyFlagBitSet_negative_noBitSet_answered() {
        let testee = ImapFlagsBits.imapNoFlagsSet()
        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .answered)
        XCTAssertFalse(isTheOnlyFlagSet, "no flag set")
    }

    func testImapOnlyFlagBitSet_negative_noBitSet_draft() {
        let testee = ImapFlagsBits.imapNoFlagsSet()
        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .draft)
        XCTAssertFalse(isTheOnlyFlagSet, "no flag set")
    }

    func testImapOnlyFlagBitSet_negative_noBitSet_flagged() {
        let testee = ImapFlagsBits.imapNoFlagsSet()
        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .flagged)
        XCTAssertFalse(isTheOnlyFlagSet, "no flag set")
    }

    func testImapOnlyFlagBitSet_negative_noBitSet_recent() {
        let testee = ImapFlagsBits.imapNoFlagsSet()
        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .recent)
        XCTAssertFalse(isTheOnlyFlagSet, "no flag set")
    }

    func testImapOnlyFlagBitSet_negative_noBitSet_seen() {
        let testee = ImapFlagsBits.imapNoFlagsSet()
        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .seen)
        XCTAssertFalse(isTheOnlyFlagSet, "no flag set")
    }

    func testImapOnlyFlagBitSet_negative_noBitSet_deleted() {
        let testee = ImapFlagsBits.imapNoFlagsSet()
        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .deleted)
        XCTAssertFalse(isTheOnlyFlagSet, "no flag set")
    }

    func testImapOnlyFlagBitSet_negativeOtherBitSetToo_anwered() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        // a second bit is set
        testee += ImapFlagBit.answered.rawValue
        testee += ImapFlagBit.deleted.rawValue

        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .answered)
        XCTAssertFalse(isTheOnlyFlagSet, "it's not the only bit set")
    }

    func testImapOnlyFlagBitSet_negativeOtherBitSetToo_draft() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        // a second bit is set
        testee += ImapFlagBit.draft.rawValue
        testee += ImapFlagBit.deleted.rawValue

        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .draft)
        XCTAssertFalse(isTheOnlyFlagSet, "it's not the only bit set")
    }

    func testImapOnlyFlagBitSet_negativeOtherBitSetToo_flagged() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        // a second bit is set
        testee += ImapFlagBit.flagged.rawValue
        testee += ImapFlagBit.deleted.rawValue

        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .flagged)
        XCTAssertFalse(isTheOnlyFlagSet, "it's not the only bit set")
    }

    func testImapOnlyFlagBitSet_negativeOtherBitSetToo_recent() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        // a second bit is set
        testee += ImapFlagBit.recent.rawValue
        testee += ImapFlagBit.deleted.rawValue

        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .recent)
        XCTAssertFalse(isTheOnlyFlagSet, "it's not the only bit set")
    }

    func testImapOnlyFlagBitSet_negativeOtherBitSetToo_seen() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        // a second bit is set
        testee += ImapFlagBit.seen.rawValue
        testee += ImapFlagBit.deleted.rawValue

        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .seen)
        XCTAssertFalse(isTheOnlyFlagSet, "it's not the only bit set")
    }

    func testImapOnlyFlagBitSet_negativeOtherBitSetToo_deleted() {
        var testee = ImapFlagsBits.imapNoFlagsSet()
        // a second bit is set
        testee += ImapFlagBit.deleted.rawValue
        testee += ImapFlagBit.answered.rawValue

        let isTheOnlyFlagSet = testee.imapOnlyFlagBitSet(is: .deleted)
        XCTAssertFalse(isTheOnlyFlagSet, "it's not the only bit set")
    }
}
