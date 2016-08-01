//
//  StringExtensionsTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS

class StringExtensionsTest: XCTestCase {
    func testValidEmail() {
        XCTAssertFalse("".isProbablyValidEmail())
        XCTAssertFalse("whe@@@uiae".isProbablyValidEmail())
        XCTAssertTrue("whe@uiae".isProbablyValidEmail())
        XCTAssertTrue("w@u".isProbablyValidEmail())
        XCTAssertFalse("whe@uiae, whe@uiae".isProbablyValidEmail())
        XCTAssertFalse("wh,e@uiae".isProbablyValidEmail())
    }

    func testUnquote() {
        let blah1 = "blah1"
        XCTAssertEqual(blah1.unquote(), blah1)
        XCTAssertEqual("\"uiaeuiae".unquote(), "\"uiaeuiae")
        XCTAssertEqual("\"uiaeuiae\"".unquote(), "uiaeuiae")
        XCTAssertEqual("\"\"".unquote(), "")
        XCTAssertEqual("uiae\"uiaeuiae\"".unquote(), "uiae\"uiaeuiae\"")
    }

    func testTrimWhiteSpace() {
        XCTAssertEqual("".trimmedWhiteSpace(), "")
        XCTAssertEqual(" ".trimmedWhiteSpace(), "")
        XCTAssertEqual("   ".trimmedWhiteSpace(), "")
        XCTAssertEqual("    abc".trimmedWhiteSpace(), "abc")
        XCTAssertEqual("    abc\t".trimmedWhiteSpace(), "abc")
        XCTAssertEqual("    abc \t ".trimmedWhiteSpace(), "abc")
        XCTAssertEqual("abc   ".trimmedWhiteSpace(), "abc")
        XCTAssertEqual(" finished2".trimmedWhiteSpace(), "finished2")
    }

    func testFinishedRecipientPart() {
        XCTAssertEqual("unfinis".finishedRecipientPart(), "")
        XCTAssertEqual("finished1,".finishedRecipientPart(), "finished1")
        XCTAssertEqual("finished, unfinis".finishedRecipientPart(), "finished")
        XCTAssertEqual("finished1, finished2, unfinis".finishedRecipientPart(),
                       "finished1, finished2")
        XCTAssertEqual("finished1, finished2, finished3, non terminado".finishedRecipientPart(),
                       "finished1, finished2, finished3")
    }

    func testMatchesPattern() {
        XCTAssertTrue("uiaeuiae, ".matchesPattern(", $"))
        XCTAssertFalse("uiaeuiae, uiae".matchesPattern(", $"))
        XCTAssertFalse("uiaeuiae, uiae".matchesPattern(",\\w*$"))
        XCTAssertTrue("uiaeuiae,".matchesPattern(",\\s*$"))
        XCTAssertTrue("uiaeuiae, ".matchesPattern(",\\s*$"))
        XCTAssertTrue("uiaeuiae,  ".matchesPattern(",\\s*$"))
        XCTAssertFalse("uiaeuiae,  .".matchesPattern(",\\s*$"))

        let whiteSpacePattern = "^\\s*$"
        XCTAssertTrue("".matchesPattern(whiteSpacePattern))
        XCTAssertTrue("   ".matchesPattern(whiteSpacePattern))
        XCTAssertFalse(" uiae  ".matchesPattern(whiteSpacePattern))
    }

    func testIsOnlyWhitespace() {
        XCTAssertTrue("   ".isOnlyWhiteSpace())
        XCTAssertTrue("".isOnlyWhiteSpace())
        XCTAssertFalse(" ui ".isOnlyWhiteSpace())
    }

    func testRemoveTrailingPattern() {
        XCTAssertEqual("just@email1.com, ".removeTrailingPattern(",\\s*"), "just@email1.com")
        XCTAssertEqual("just@email1.com,   ".removeTrailingPattern(",\\s*"), "just@email1.com")
    }

    func testRemoveLeadingPattern() {
        XCTAssertEqual("To: test005@peptest.ch".removeLeadingPattern("\\w*:\\s*"),
                       "test005@peptest.ch")
    }

    func testIsProbablyValidEmailList() {
        XCTAssertFalse("email1, email2".isProbablyValidEmailListSeparatedBy(","))
        XCTAssertTrue("email1@test.com, email2@test.com".isProbablyValidEmailListSeparatedBy(","))
        XCTAssertTrue("email1@test.com; email2@test.com".isProbablyValidEmailListSeparatedBy(";"))
        XCTAssertFalse("email1@test.com, email2@test.com".isProbablyValidEmailListSeparatedBy(";"))
        XCTAssertFalse(
            "email1@test.com, email2@test.com, email, test@com".isProbablyValidEmailListSeparatedBy(
            ","))
    }

    func testComponentsSeparatedBy() {
        // This behavior is somewhat odd. Want to make sure it's documented.
        XCTAssertEqual("".componentsSeparatedByString(","), [""])
    }
}
