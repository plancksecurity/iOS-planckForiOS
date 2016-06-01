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
    func testValidEmail() {
        XCTAssertFalse("".isProbablyValidEmail())
        XCTAssertFalse("whe@@@uiae".isProbablyValidEmail())
        XCTAssertTrue("whe@uiae".isProbablyValidEmail())
        XCTAssertTrue("w@u".isProbablyValidEmail())
    }

    func testUnquote() {
        let blah1 = "blah1"
        XCTAssertEqual(blah1.unquote(), blah1)
        XCTAssertEqual("\"uiaeuiae".unquote(), "\"uiaeuiae")
        XCTAssertEqual("\"uiaeuiae\"".unquote(), "uiaeuiae")
        XCTAssertEqual("\"\"".unquote(), "")
        XCTAssertEqual("uiae\"uiaeuiae\"".unquote(), "uiae\"uiaeuiae\"")
    }

    func testSignedNumbers32() {
        let u: UInt32 = UInt32.max
        let s: Int32 = Int32(bitPattern: u)
        let u1: UInt32 = UInt32(bitPattern: s)
        XCTAssertEqual(u1, UInt32.max)

        let n = NSNumber.init(int: s)
        let u2: UInt32 = UInt32(bitPattern: n.intValue)
        XCTAssertEqual(u2, UInt32.max)
    }
}