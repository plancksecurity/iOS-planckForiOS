//
//  PantomimeSpecialUseMailboxType+ExtensionsTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 06.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

class PantomimeSpecialUseMailboxType_ExtensionsTest: XCTestCase {

    func testSpecialUseMailboxNormal() {
        let testee = PantomimeSpecialUseMailboxNormal
        XCTAssertTrue(testee.imapSpecialUseMailboxNormal)
        XCTAssertFalse(testee.imapSpecialUseMailboxAll)
        XCTAssertFalse(testee.imapSpecialUseMailboxArchive)
        XCTAssertFalse(testee.imapSpecialUseMailboxDrafts)
        XCTAssertFalse(testee.imapSpecialUseMailboxFlagged)
        XCTAssertFalse(testee.imapSpecialUseMailboxJunk)
        XCTAssertFalse(testee.imapSpecialUseMailboxSent)
        XCTAssertFalse(testee.imapSpecialUseMailboxTrash)
    }

    func testSpecialUseMailboxAll() {
        let testee = PantomimeSpecialUseMailboxAll
        XCTAssertTrue(testee.imapSpecialUseMailboxAll)
        XCTAssertFalse(testee.imapSpecialUseMailboxNormal)
        XCTAssertFalse(testee.imapSpecialUseMailboxArchive)
        XCTAssertFalse(testee.imapSpecialUseMailboxDrafts)
        XCTAssertFalse(testee.imapSpecialUseMailboxFlagged)
        XCTAssertFalse(testee.imapSpecialUseMailboxJunk)
        XCTAssertFalse(testee.imapSpecialUseMailboxSent)
        XCTAssertFalse(testee.imapSpecialUseMailboxTrash)
    }

    func testSpecialUseMailboxArchive() {
        let testee = PantomimeSpecialUseMailboxArchive
        XCTAssertTrue(testee.imapSpecialUseMailboxArchive)
        XCTAssertFalse(testee.imapSpecialUseMailboxNormal)
        XCTAssertFalse(testee.imapSpecialUseMailboxAll)
        XCTAssertFalse(testee.imapSpecialUseMailboxDrafts)
        XCTAssertFalse(testee.imapSpecialUseMailboxFlagged)
        XCTAssertFalse(testee.imapSpecialUseMailboxJunk)
        XCTAssertFalse(testee.imapSpecialUseMailboxSent)
        XCTAssertFalse(testee.imapSpecialUseMailboxTrash)
    }

    func testSpecialUseMailboxDrafts() {
        let testee = PantomimeSpecialUseMailboxDrafts
        XCTAssertTrue(testee.imapSpecialUseMailboxDrafts)
        XCTAssertFalse(testee.imapSpecialUseMailboxNormal)
        XCTAssertFalse(testee.imapSpecialUseMailboxAll)
        XCTAssertFalse(testee.imapSpecialUseMailboxArchive)
        XCTAssertFalse(testee.imapSpecialUseMailboxFlagged)
        XCTAssertFalse(testee.imapSpecialUseMailboxJunk)
        XCTAssertFalse(testee.imapSpecialUseMailboxSent)
        XCTAssertFalse(testee.imapSpecialUseMailboxTrash)
    }

    func testSpecialUseMailboxFlagged() {
        let testee = PantomimeSpecialUseMailboxFlagged
        XCTAssertTrue(testee.imapSpecialUseMailboxFlagged)
        XCTAssertFalse(testee.imapSpecialUseMailboxNormal)
        XCTAssertFalse(testee.imapSpecialUseMailboxAll)
        XCTAssertFalse(testee.imapSpecialUseMailboxArchive)
        XCTAssertFalse(testee.imapSpecialUseMailboxDrafts)
        XCTAssertFalse(testee.imapSpecialUseMailboxJunk)
        XCTAssertFalse(testee.imapSpecialUseMailboxSent)
        XCTAssertFalse(testee.imapSpecialUseMailboxTrash)
    }

    func testSpecialUseMailboxJunk() {
        let testee = PantomimeSpecialUseMailboxJunk
        XCTAssertTrue(testee.imapSpecialUseMailboxJunk)
        XCTAssertFalse(testee.imapSpecialUseMailboxNormal)
        XCTAssertFalse(testee.imapSpecialUseMailboxAll)
        XCTAssertFalse(testee.imapSpecialUseMailboxArchive)
        XCTAssertFalse(testee.imapSpecialUseMailboxDrafts)
        XCTAssertFalse(testee.imapSpecialUseMailboxFlagged)
        XCTAssertFalse(testee.imapSpecialUseMailboxSent)
        XCTAssertFalse(testee.imapSpecialUseMailboxTrash)
    }

    func testSpecialUseMailboxSent() {
        let testee = PantomimeSpecialUseMailboxSent
        XCTAssertTrue(testee.imapSpecialUseMailboxSent)
        XCTAssertFalse(testee.imapSpecialUseMailboxNormal)
        XCTAssertFalse(testee.imapSpecialUseMailboxAll)
        XCTAssertFalse(testee.imapSpecialUseMailboxArchive)
        XCTAssertFalse(testee.imapSpecialUseMailboxDrafts)
        XCTAssertFalse(testee.imapSpecialUseMailboxFlagged)
        XCTAssertFalse(testee.imapSpecialUseMailboxJunk)
        XCTAssertFalse(testee.imapSpecialUseMailboxTrash)
    }

    func testSpecialUseMailboxTrash() {
        let testee = PantomimeSpecialUseMailboxTrash
        XCTAssertTrue(testee.imapSpecialUseMailboxTrash)
        XCTAssertFalse(testee.imapSpecialUseMailboxNormal)
        XCTAssertFalse(testee.imapSpecialUseMailboxAll)
        XCTAssertFalse(testee.imapSpecialUseMailboxArchive)
        XCTAssertFalse(testee.imapSpecialUseMailboxDrafts)
        XCTAssertFalse(testee.imapSpecialUseMailboxFlagged)
        XCTAssertFalse(testee.imapSpecialUseMailboxJunk)
        XCTAssertFalse(testee.imapSpecialUseMailboxSent)
    }
}
