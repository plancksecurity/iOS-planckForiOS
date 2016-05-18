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
}