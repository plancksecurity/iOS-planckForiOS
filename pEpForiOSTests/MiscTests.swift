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
    let waitTime: NSTimeInterval = 10

    func testSignedNumbers32() {
        let u: UInt32 = UInt32.max
        let s: Int32 = Int32(bitPattern: u)
        let u1: UInt32 = UInt32(bitPattern: s)
        XCTAssertEqual(u1, UInt32.max)

        let n = NSNumber.init(int: s)
        let u2: UInt32 = UInt32(bitPattern: n.intValue)
        XCTAssertEqual(u2, UInt32.max)
    }

    func testExtractRecipientFromText() {
        XCTAssertNil(ComposeViewController.extractRecipientFromText("", aroundCaretPosition: 5))
        XCTAssertNil(ComposeViewController.extractRecipientFromText("01", aroundCaretPosition: 3))
        XCTAssertNil(ComposeViewController.extractRecipientFromText("001,002",
            aroundCaretPosition: 4))
        XCTAssertEqual(ComposeViewController.extractRecipientFromText(
            "001,002", aroundCaretPosition: 5), "002")
        XCTAssertEqual(ComposeViewController.extractRecipientFromText(
            "001, 002 ", aroundCaretPosition: 6), "002")
        XCTAssertNil(ComposeViewController.extractRecipientFromText(
            "to: 001, 002 ", aroundCaretPosition: 3))
        XCTAssertEqual(ComposeViewController.extractRecipientFromText(
            "to: 001, 002 ", aroundCaretPosition: 4), "001")
        XCTAssertEqual(ComposeViewController.extractRecipientFromText(
            "to: 001, 002 ", aroundCaretPosition: 7), "001")
        XCTAssertNil(ComposeViewController.extractRecipientFromText(
            "to: 001, 002 ", aroundCaretPosition: 8))
        XCTAssertEqual(ComposeViewController.extractRecipientFromText(
            "to: 001, 002 ", aroundCaretPosition: 9), "002")
    }
}