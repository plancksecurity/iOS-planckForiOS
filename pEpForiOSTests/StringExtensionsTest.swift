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
    func testTrimWhiteSpace() {
        XCTAssertEqual("".trimmedWhiteSpace(), "")
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
        XCTAssertEqual("uiaeuiae, ".matchesPattern(", $"), true)
        XCTAssertEqual("uiaeuiae, uiae".matchesPattern(", $"), false)
        XCTAssertEqual("uiaeuiae, uiae".matchesPattern(",\\w*$"), false)
        XCTAssertEqual("uiaeuiae,".matchesPattern(",\\s*$"), true)
        XCTAssertEqual("uiaeuiae, ".matchesPattern(",\\s*$"), true)
        XCTAssertEqual("uiaeuiae,  ".matchesPattern(",\\s*$"), true)
        XCTAssertEqual("uiaeuiae,  .".matchesPattern(",\\s*$"), false)
    }
}
