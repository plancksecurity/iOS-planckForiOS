//
//  PantomimeFolderAttribute+ExtensionsTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 06.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

import PantomimeFramework

@testable import MessageModel

class PantomimeFolderAttribute_ExtensionsTest: XCTestCase {

    func testPantomimeHoldsFolders() {
        let testee = PantomimeHoldsFolders
        XCTAssertTrue(testee.imapAttributeHoldsFolders)
        XCTAssertFalse(testee.imapAttributeHoldsMessages)
        XCTAssertFalse(testee.imapAttributeNoInferiors)
        XCTAssertFalse(testee.imapAttributeNoSelect)
        XCTAssertFalse(testee.imapAttributeMarked)
        XCTAssertFalse(testee.imapAttributeUnmarked)
    }

    func testPantomimeHoldsMessages() {
        let testee = PantomimeHoldsMessages
        XCTAssertTrue(testee.imapAttributeHoldsMessages)
        XCTAssertFalse(testee.imapAttributeHoldsFolders)
        XCTAssertFalse(testee.imapAttributeNoInferiors)
        XCTAssertFalse(testee.imapAttributeNoSelect)
        XCTAssertFalse(testee.imapAttributeMarked)
        XCTAssertFalse(testee.imapAttributeUnmarked)
    }

    func testPantomimeNoInferiors() {
        let testee = PantomimeNoInferiors
        XCTAssertTrue(testee.imapAttributeNoInferiors)
        XCTAssertFalse(testee.imapAttributeHoldsFolders)
        XCTAssertFalse(testee.imapAttributeHoldsMessages)
        XCTAssertFalse(testee.imapAttributeNoSelect)
        XCTAssertFalse(testee.imapAttributeMarked)
        XCTAssertFalse(testee.imapAttributeUnmarked)
    }

    func testPantomimeNoSelect() {
        let testee = PantomimeNoSelect
        XCTAssertTrue(testee.imapAttributeNoSelect)
        XCTAssertFalse(testee.imapAttributeHoldsFolders)
        XCTAssertFalse(testee.imapAttributeHoldsMessages)
        XCTAssertFalse(testee.imapAttributeNoInferiors)
        XCTAssertFalse(testee.imapAttributeMarked)
        XCTAssertFalse(testee.imapAttributeUnmarked)
    }

    func testPantomimeMarked() {
        let testee = PantomimeMarked
        XCTAssertTrue(testee.imapAttributeMarked)
        XCTAssertFalse(testee.imapAttributeHoldsFolders)
        XCTAssertFalse(testee.imapAttributeHoldsMessages)
        XCTAssertFalse(testee.imapAttributeNoInferiors)
        XCTAssertFalse(testee.imapAttributeNoSelect)
        XCTAssertFalse(testee.imapAttributeUnmarked)
    }

    func testPantomimeUnmarked() {
        let testee = PantomimeUnmarked
        XCTAssertTrue(testee.imapAttributeUnmarked)
        XCTAssertFalse(testee.imapAttributeHoldsFolders)
        XCTAssertFalse(testee.imapAttributeHoldsMessages)
        XCTAssertFalse(testee.imapAttributeNoInferiors)
        XCTAssertFalse(testee.imapAttributeNoSelect)
        XCTAssertFalse(testee.imapAttributeMarked)
    }
}
