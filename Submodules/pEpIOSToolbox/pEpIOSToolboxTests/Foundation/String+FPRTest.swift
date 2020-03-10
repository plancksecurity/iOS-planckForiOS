//
//  String+FPRTest.swift
//  pEpIOSToolboxTests
//
//  Created by Andreas Buff on 14.08.19.
//  Copyright © 2019 pEp Security SA. All rights reserved.
//

import XCTest

class String_FPRTest: XCTestCase {

    // MARK: - toValidFpr

    func testToValidFpr_emptyStr() {
        let testee = ""
        XCTAssertNil(testee.toValidFpr)
    }

    func testToValidFpr_tooShort() {
        let testee = "123456789012345"
        XCTAssertNil(testee.toValidFpr)
    }

    func testToValidFpr_nothingStripedDigits() {
        let testee = "1234567890123456789012345678901234567890"
        XCTAssertEqual(testee.toValidFpr, testee)
    }

    func testToValidFpr_nothingStripedLetters() {
        let testee = "ABCSWEKGUSKGURPSJFFURKWSAFITBNQQWERTZUIO"
        XCTAssertEqual(testee.toValidFpr, testee)
    }

    func testToValidFpr_validStriped_collon() {
        let testee = "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8"
        let expected = "435143a1b5fc8bb70a3aa9b10f6673a8"
        XCTAssertEqual(testee.toValidFpr, expected)
    }

    func testToValidFpr_validStriped_minus() {
        let testee = "4351-43a1-b5fc-8bb7-0a3a-a9b1-0f66-73a8"
        let expected = "435143a1b5fc8bb70a3aa9b10f6673a8"
        XCTAssertEqual(testee.toValidFpr, expected)
    }

    func testToValidFpr_validStriped_space() {
        let testee = "4351 43a1 b5fc 8bb7 0a3a a9b1 0f66 73a8"
        let expected = "435143a1b5fc8bb70a3aa9b10f6673a8"
        XCTAssertEqual(testee.toValidFpr, expected)
    }
}
