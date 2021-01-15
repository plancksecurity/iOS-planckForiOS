//
//  CdImapFields+ImapFlagsTests.swift
//  MessageModel
//
//  Created by Andreas Buff on 15/03/2017.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel

class CdImapFields_ImapFlagsTests: PersistentStoreDrivenTestBase {

    // MARK: - flagsCurrent

    func testFlagsCurrent_answered() {
        let imap = imapFieldsWithAllFlagsCurrentSet(to: false)
        imap.localFlags?.flagAnswered = true

        let flagsCurrent = imap.localFlags ?? CdImapFlags(context: Stack.shared.mainContext)
        XCTAssertTrue(flagsCurrent.rawFlagsAsShort().imapOnlyFlagBitSet(is: .answered),
                      "flag is set")
    }

    func testFlagsCurrent_draft() {
        let imap = imapFieldsWithAllFlagsCurrentSet(to: false)
        imap.localFlags?.flagDraft = true

        let flagsCurrent = imap.localFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(flagsCurrent.rawFlagsAsShort().imapOnlyFlagBitSet(is: .draft), "flag is set")
    }

    func testFlagsCurrent_flagged() {
        let imap = imapFieldsWithAllFlagsCurrentSet(to: false)
        imap.localFlags?.flagFlagged = true

        let flagsCurrent = imap.localFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(flagsCurrent.rawFlagsAsShort().imapOnlyFlagBitSet(is: .flagged),
                      "flag is set")
    }

    func testFlagsCurrent_recent() {
        let imap = imapFieldsWithAllFlagsCurrentSet(to: false)
        imap.localFlags?.flagRecent = true

        let flagsCurrent = imap.localFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(flagsCurrent.rawFlagsAsShort().imapOnlyFlagBitSet(is: .recent), "flag is set")
    }

    func testFlagsCurrent_seen() {
        let imap = imapFieldsWithAllFlagsCurrentSet(to: false)
        imap.localFlags?.flagSeen = true

        let flagsCurrent = imap.localFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(flagsCurrent.rawFlagsAsShort().imapOnlyFlagBitSet(is: .seen), "flag is set")
    }

    func testFlagsCurrent_deleted() {
        let imap = imapFieldsWithAllFlagsCurrentSet(to: false)
        imap.localFlags?.flagDeleted = true

        let flagsCurrent = imap.localFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(flagsCurrent.rawFlagsAsShort().imapOnlyFlagBitSet(is: .deleted),
                      "flag is set")
    }

    // MARK: - flagsFromServer

    // MARK: GET

    // MARK: starting from all true

    func testFlagsFromServerGet_allZero_answered() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)
        imap.serverFlags?.flagAnswered = true

        let flagsFromServer = imap.serverFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(flagsFromServer.rawFlagsAsShort().imapOnlyFlagBitSet(is: .answered),
                      "flag is set")
    }

    func testFlagsFromServerGet_allZero_draft() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)
        imap.serverFlags?.flagDraft = true

        let flagsFromServer = imap.serverFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(flagsFromServer.rawFlagsAsShort().imapOnlyFlagBitSet(is: .draft),
                      "flag is set")
    }

    func testFlagsFromServerGet_allZero_flagged() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)
        imap.serverFlags?.flagFlagged = true

        let flagsFromServer = imap.serverFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(flagsFromServer.rawFlagsAsShort().imapOnlyFlagBitSet(is: .flagged),
                      "flag is set")
    }

    func testFlagsFromServerGet_allZero_recent() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)
        imap.serverFlags?.flagRecent = true

        let flagsFromServer = imap.serverFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(flagsFromServer.rawFlagsAsShort().imapOnlyFlagBitSet(is: .recent),
                      "flag is set")
    }

    func testFlagsFromServerGet_allZero_seen() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)
        imap.serverFlags?.flagSeen = true

        let flagsFromServer = imap.serverFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(flagsFromServer.rawFlagsAsShort().imapOnlyFlagBitSet(is: .seen),
                      "flag is set")
    }

    func testFlagsFromServerGet_allZero_deleted() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)
        imap.serverFlags?.flagDeleted = true

        let flagsFromServer = imap.serverFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(flagsFromServer.rawFlagsAsShort().imapOnlyFlagBitSet(is: .deleted),
                      "flag is set")
    }

    // MARK: starting from all true

    func testFlagsFromServerGet_allOne_answered() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)
        imap.serverFlags?.flagAnswered = false

        let flagsFromServer = imap.serverFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: flagsFromServer.rawFlagsAsShort()),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerGet_allOne_draft() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)
        imap.serverFlags?.flagDraft = true

        let flagsFromServer = imap.serverFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: flagsFromServer.rawFlagsAsShort()),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerGet_allOne_flagged() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)
        imap.serverFlags?.flagFlagged = true

        let flagsFromServer = imap.serverFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: flagsFromServer.rawFlagsAsShort()),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerGet_allOne_recent() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)
        imap.serverFlags?.flagRecent = true

        let flagsFromServer = imap.serverFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: flagsFromServer.rawFlagsAsShort()),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerGet_allOne_seen() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)
        imap.serverFlags?.flagSeen = true

        let flagsFromServer = imap.serverFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: flagsFromServer.rawFlagsAsShort()),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerGet_allOne_deleted() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)
        imap.serverFlags?.flagDeleted = true

        let flagsFromServer = imap.serverFlags ?? CdImapFlags(context: moc)
        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: flagsFromServer.rawFlagsAsShort()),
                      "the boolen flagFromServer... properties are set correctly")
    }

    //MAKR: SET

    func testFlagsFromServerSet_allZero_answered() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)

        let flagsToTest: [ImapFlagBit] = [.answered]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allZero_draft() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)

        let flagsToTest: [ImapFlagBit] = [.draft]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allZero_flagged() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)

        let flagsToTest: [ImapFlagBit] = [.flagged]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allZero_recent() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)

        let flagsToTest: [ImapFlagBit] = [.recent]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allZero_seen() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)

        let flagsToTest: [ImapFlagBit] = [.seen]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allZero_deleted() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)

        let flagsToTest: [ImapFlagBit] = [.deleted]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allZero_multi_1() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)

        let flagsToTest: [ImapFlagBit] = [.answered, .draft, .deleted]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allZero_multi_2() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: false)

        let flagsToTest: [ImapFlagBit] = [.flagged, .recent, .seen]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)
        
        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allOne_answered() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)

        let flagsToTest: [ImapFlagBit] = [.answered]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allOne_draft() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)

        let flagsToTest: [ImapFlagBit] = [.draft]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allOne_flagged() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)

        let flagsToTest: [ImapFlagBit] = [.flagged]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allOne_recent() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)

        let flagsToTest: [ImapFlagBit] = [.recent]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allOne_seen() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)

        let flagsToTest: [ImapFlagBit] = [.seen]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allOne_deleted() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)

        let flagsToTest: [ImapFlagBit] = [.deleted]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allOne_multi_1() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)

        let flagsToTest: [ImapFlagBit] = [.answered, .draft, .deleted]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)

        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    func testFlagsFromServerSet_allOne_multi_2() {
        let imap = imapFieldsWithAllFlagsFromServerSet(to: true)

        let flagsToTest: [ImapFlagBit] = [.flagged, .recent, .seen]

        // setup flagsFromServer bits ...
        var newFlagBits = ImapFlagsBits.imapNoFlagsSet()
        for flag in flagsToTest {
            newFlagBits.imapSetFlagBit(flag)
        }
        // ... and set them
        imap.serverFlags?.update(rawValue16: newFlagBits)
        
        XCTAssertTrue(imap.flagsFromServerBoolsEqual(flagBits: newFlagBits),
                      "the boolen flagFromServer... properties are set correctly")
    }

    // MARK: - HELPER

    private func imapFieldsWithAllFlagsFromServerSet(to value:Bool) -> CdImapFields {
        let imap = CdImapFields(context: moc)

        let serverFlags = CdImapFlags(context: moc)
        imap.serverFlags = serverFlags

        serverFlags.flagAnswered = value
        serverFlags.flagDraft = value
        serverFlags.flagFlagged = value
        serverFlags.flagRecent = value
        serverFlags.flagSeen = value
        serverFlags.flagDeleted = value

        return imap
    }

    private func imapFieldsWithAllFlagsCurrentSet(to value:Bool) -> CdImapFields {
        let imap = CdImapFields(context: moc)

        let localFlags = CdImapFlags(context: moc)
        imap.localFlags = localFlags

        localFlags.flagAnswered = value
        localFlags.flagDraft = value
        localFlags.flagFlagged = value
        localFlags.flagRecent = value
        localFlags.flagSeen = value
        localFlags.flagDeleted = value

        return imap
    }
}
