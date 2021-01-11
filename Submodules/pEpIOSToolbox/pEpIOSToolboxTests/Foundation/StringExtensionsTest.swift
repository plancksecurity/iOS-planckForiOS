//
//  StringExtensionsTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 13/07/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest

class StringExtensionsTest: XCTestCase {
    func testValidEmail() {
        let testData = [("", false),
                        ("whe@@@uiae", false),
                        ("whe@uiae", true),
                        ("w@u", true),
                        ("whe@uiae, whe@uiae", false),
                        ("wh,e@uiae", false),
                        ("simple@example.com", true),
                        ("very.common@example.com", true),
                        ("disposable.style.email.with+symbol@example.com", true),
                        ("other.email-with-hyphen@example.com", true),
                        ("fully-qualified-domain@example.com", true),
                        ("user.name+tag+sorting@example.com", true),
                        ("x@example.com", true),
                        ("example-indeed@strange-example.com", true),
                        ("admin@mailserver1", true),
                        ("#!$%&'*+-/=?^_`{}|~@example.org", true),
                        ("example@s.example", true),
                        ("Abc.example.com", false),
                        ("A@b@c@example.com", false),
                        ("1234567890123456789012345678901234567890123456789012345678901234+x@example.com", false),
                        ("john..doe@example.com", false),
                        ("john.doe@example..com", false)]

        for (email, isValid) in testData {
            if isValid {
                XCTAssertTrue(email.isProbablyValidEmail(),
                              "expected \(email) to be valid")
            } else {
                XCTAssertFalse(email.isProbablyValidEmail(),
                               "expected \(email) to NOT be valid")
            }
        }
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
        XCTAssertEqual("".trimmed(), "")
        XCTAssertEqual(" ".trimmed(), "")
        XCTAssertEqual("   ".trimmed(), "")
        XCTAssertEqual("    abc".trimmed(), "abc")
        XCTAssertEqual("    abc\t".trimmed(), "abc")
        XCTAssertEqual("    abc \t ".trimmed(), "abc")
        XCTAssertEqual("abc   ".trimmed(), "abc")
        XCTAssertEqual(" finished2".trimmed(), "finished2")

        XCTAssertEqual("".trimmed(), "")
        XCTAssertEqual(" ".trimmed(), "")
        XCTAssertEqual("uze".trimmed(), "uze")
        XCTAssertEqual("\nuze".trimmed(), "uze")
        XCTAssertEqual("\nuze\r\n".trimmed(), "uze")
        XCTAssertEqual("\r\n\nuze\r\n".trimmed(), "uze")
        XCTAssertEqual("\n\r\n\nuze\r\n".trimmed(), "uze")

        XCTAssertEqual("\r\n\r\n\nuze\r\n".trimmed(), "uze")
        XCTAssertEqual("\r\n\r\n\r\n\nuze\r\n".trimmed(), "uze")
        XCTAssertEqual("\r\n\r\n\r\nuze".trimmed(), "uze")
        XCTAssertEqual("\r\n\r\n\r\n\nuze\r\n\r\r\r\n\r\n".trimmed(), "uze")
        XCTAssertEqual("Whatever New ".trimmed(), "Whatever New")
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

    func testIsValidDomainAndisValidDomainDnsLabel() {
        let domainLabelTestData = [
            ("uiaeuiae-", false),
            ("-uiaeuia", false),
            ("uia-euia", true),
            ("uia-666-euia", true),
            ("9uia666euia9", true),
            ("9uia66.6euia9", false),
            ("aeaaaaaaaaaeaaaaaaaaaeaaaaaaaaaeaaaaaaaaaeaaaaaaaaaeaaaaaaaaaeaaaaaaaa", false),
            ("blah", true)]

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
