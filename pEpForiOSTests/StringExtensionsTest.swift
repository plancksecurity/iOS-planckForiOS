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
        XCTAssertEqual("".components(separatedBy: ","), [""])
    }

    func testRemoveAngleBrackets() {
        XCTAssertEqual("messageid".removeAngleBrackets(), "messageid")
        XCTAssertEqual("<messageid@someserver>".removeAngleBrackets(), "messageid@someserver")
        XCTAssertEqual("  <messageid@someserver>  ".removeAngleBrackets(),
                       "messageid@someserver")
    }

    func testExtractTextFromHTML() {
        var html = "<html>\r\n  <head>\r\n\r\n"
            + "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\r\n"
            + "</head>\r\n  <body bgcolor=\"#FFFFFF\" text=\"#000000\">\r\n"
            + "<p>HTML! <b>Yes!</b><br>\r\n"
            + "</p>\r\n  </body>\r\n</html>\r\n"
        XCTAssertEqual(html.extractTextFromHTML(), "HTML! Yes!")

        html = "<html>\r\n  <head>\r\n\r\n"
            + "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\r\n"
            + "</head>\r\n  <body bgcolor=\"#FFFFFF\" text=\"#000000\">\r\n"
            + "<p>HTML! <b>Yes!</b><br>\r\n"
            + "</p><p>Whatever. New paragraph.</p>\r\n  </body>\r\n</html>\r\n"
        XCTAssertEqual(html.extractTextFromHTML(), "HTML! Yes!  Whatever. New paragraph.")

        html = "<html>\r\n  <head>\r\n\r\n"
            + "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\r\n"
            + "</head>\r\n  <body bgcolor=\"#FFFFFF\" text=\"#000000\">\r\n"
            + "<p>HTML! <b>Yes!</b><br>\r\n"
            + "</p><p>Whatever. New <b>bold</b> paragraph.</p>\r\n  </body>\r\n</html>\r\n"
        XCTAssertEqual(
            html.extractTextFromHTML(), "HTML! Yes!  Whatever. New bold paragraph.")
    }

    func testToMarkdown() {
        guard let data = TestUtil.loadData(fileName: "NSHTML_2017-08-09 15_40_53 +0000.html") else {
            XCTFail()
            return
        }
        guard let inputString = String(data: data, encoding: String.Encoding.utf8) else {
            XCTFail()
            return
        }
        guard let mdString = inputString.htmlToSimpleMarkdown() else {
            XCTFail()
            return
        }
        XCTAssertTrue(mdString.characters.count > 0)
        XCTAssertNotEqual(mdString, inputString)
    }
}
