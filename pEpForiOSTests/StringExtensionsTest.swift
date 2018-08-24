//
//  StringExtensionsTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS

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

    func testTrimmedWhiteSpace() {
        XCTAssertEqual("".trimmedWhiteSpace(), "")
        XCTAssertEqual(" ".trimmedWhiteSpace(), "")
        XCTAssertEqual("   ".trimmedWhiteSpace(), "")
        XCTAssertEqual("    abc".trimmedWhiteSpace(), "abc")
        XCTAssertEqual("    abc\t".trimmedWhiteSpace(), "abc")
        XCTAssertEqual("    abc \t ".trimmedWhiteSpace(), "abc")
        XCTAssertEqual("abc   ".trimmedWhiteSpace(), "abc")
        XCTAssertEqual(" finished2".trimmedWhiteSpace(), "finished2")

        XCTAssertEqual("".trimmedWhiteSpace(), "")
        XCTAssertEqual(" ".trimmedWhiteSpace(), "")
        XCTAssertEqual("uze".trimmedWhiteSpace(), "uze")
        XCTAssertEqual("\nuze".trimmedWhiteSpace(), "uze")
        XCTAssertEqual("\nuze\r\n".trimmedWhiteSpace(), "uze")
        XCTAssertEqual("\r\n\nuze\r\n".trimmedWhiteSpace(), "uze")
        XCTAssertEqual("\n\r\n\nuze\r\n".trimmedWhiteSpace(), "uze")

        XCTAssertEqual("\r\n\r\n\nuze\r\n".trimmedWhiteSpace(), "uze")
        XCTAssertEqual("\r\n\r\n\r\n\nuze\r\n".trimmedWhiteSpace(), "uze")
        XCTAssertEqual("\r\n\r\n\r\nuze".trimmedWhiteSpace(), "uze")
        XCTAssertEqual("\r\n\r\n\r\n\nuze\r\n\r\r\r\n\r\n".trimmedWhiteSpace(), "uze")
        XCTAssertEqual("Whatever New ".trimmedWhiteSpace(), "Whatever New")
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
        XCTAssertTrue("uiaeuiae, ".matches(pattern: ", $"))
        XCTAssertFalse("uiaeuiae, uiae".matches(pattern: ", $"))
        XCTAssertFalse("uiaeuiae, uiae".matches(pattern: ",\\w*$"))
        XCTAssertTrue("uiaeuiae,".matches(pattern: ",\\s*$"))
        XCTAssertTrue("uiaeuiae, ".matches(pattern: ",\\s*$"))
        XCTAssertTrue("uiaeuiae,  ".matches(pattern: ",\\s*$"))
        XCTAssertFalse("uiaeuiae,  .".matches(pattern: ",\\s*$"))

        let whiteSpacePattern = "^\\s*$"
        XCTAssertTrue("".matches(pattern: whiteSpacePattern))
        XCTAssertTrue("   ".matches(pattern: whiteSpacePattern))
        XCTAssertFalse(" uiae  ".matches(pattern: whiteSpacePattern))
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
        XCTAssertEqual("".components(separatedBy: ","), [""])
    }

    func testIsGmailAddress() {
        XCTAssertFalse("blah@googlemail.com".isGmailAddress)
        XCTAssertFalse("blah@nogmail.com".isGmailAddress)
        XCTAssertTrue("blah@gmail.com".isGmailAddress)
        XCTAssertTrue("blah@gmail.notyet".isGmailAddress)
        XCTAssertTrue("üöäp-b___la0654654h@gmail.notyet".isGmailAddress)
    }

    let domainLabelTestData = [
        ("uiaeuiae-", false),
        ("-uiaeuia", false),
        ("uia-euia", true),
        ("uia-666-euia", true),
        ("9uia666euia9", true),
        ("9uia66.6euia9", false),
        ("aeaaaaaaaaaeaaaaaaaaaeaaaaaaaaaeaaaaaaaaaeaaaaaaaaaeaaaaaaaaaeaaaaaaaa", false),
        ("blah", true)]

    func testIsValidDomainAndisValidDomainDnsLabel() {
        for (name, shouldPass) in domainLabelTestData {
            if shouldPass {
                let domain1 = "\(name).\(name).\(name)"
                XCTAssertTrue(
                    domain1.isValidDomain(),
                    "expected \(domain1) to be a valid domain")

                let invalidDomainLabels = domainLabelTestData.filter { (n, shouldPass) in
                    return !shouldPass
                }
                for (invalidLabel, _) in invalidDomainLabels {
                    let theLabel = invalidLabel.replacingOccurrences(of: ".", with: "")
                    if !theLabel.isValidDomainDnsLabel() {
                        let domain2 = "\(domain1).\(theLabel)"
                        XCTAssertFalse(
                            domain2.isValidDomain(),
                            "expected \(domain2) to NOT be a valid domain")
                    }
                }
            } else {
                let theLabel = name.replacingOccurrences(of: ".", with: "")
                if !theLabel.isValidDomainDnsLabel() {
                    let domain = "\(name).\(name).\(name)"
                    XCTAssertFalse(
                        domain.isValidDomain(),
                        "expected \(domain) to NOT be a valid domain")
                }
            }
        }
    }
}
