//
//  MiscTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest

import pEpForiOS

/**
 Tests for things not covered elsewhere.
 */
class MiscTests: XCTestCase {
    func testSignedNumbers32() {
        let u: UInt32 = UInt32.max
        let s: Int32 = Int32(bitPattern: u)
        let u1: UInt32 = UInt32(bitPattern: s)
        XCTAssertEqual(u1, UInt32.max)

        let n = NSNumber.init(value: s as Int32)
        let u2: UInt32 = UInt32(bitPattern: n.int32Value)
        XCTAssertEqual(u2, UInt32.max)
    }

    func testMimeTypeJson() {
        //PEPUtil
        let s = MimeTypeUtil.getMimeType(Extension: "pdf")
        XCTAssertEqual(s, "application/pdf")
    }

    /*
    func testExtractRecipientFromText() {
        XCTAssertNil(ComposeViewHelper.extractRecipientFromText("", aroundCaretPosition: 5))
        XCTAssertNil(ComposeViewHelper.extractRecipientFromText("01", aroundCaretPosition: 3))
        XCTAssertNil(ComposeViewHelper.extractRecipientFromText("001,002",
            aroundCaretPosition: 4))
        XCTAssertEqual(ComposeViewHelper.extractRecipientFromText(
            "001,002", aroundCaretPosition: 5), "002")
        XCTAssertEqual(ComposeViewHelper.extractRecipientFromText(
            "001, 002 ", aroundCaretPosition: 6), "002")
        XCTAssertNil(ComposeViewHelper.extractRecipientFromText(
            "to: 001, 002 ", aroundCaretPosition: 3))
        XCTAssertEqual(ComposeViewHelper.extractRecipientFromText(
            "to: 001, 002 ", aroundCaretPosition: 4), "001")
        XCTAssertEqual(ComposeViewHelper.extractRecipientFromText(
            "to: 001, 002 ", aroundCaretPosition: 7), "001")
        XCTAssertNil(ComposeViewHelper.extractRecipientFromText(
            "to: 001, 002 ", aroundCaretPosition: 8))
        XCTAssertEqual(ComposeViewHelper.extractRecipientFromText(
            "to: 001, 002 ", aroundCaretPosition: 9), "002")
    }
     */
}
