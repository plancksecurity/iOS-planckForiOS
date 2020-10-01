//
//  StringHTMLExtensionTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import UIKit

@testable import pEpForiOS
@testable import MessageModel
import pEpIOSToolbox

// StringHTMLExtensionTests all tests are green on date 20200313

class StringHTMLExtensionTests: XCTestCase {
    let pepSignatureTrimmed = String.pepSignature.trimmed()

    func testExtractTextFromHTML() {
        var html = "<html>\r\n  <head>\r\n\r\n"
            + "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\r\n"
            + "</head>\r\n  <body bgcolor=\"#FFFFFF\" text=\"#000000\">\r\n"
            + "<p>HTML! <b>Yes!</b><br>\r\n"
            + "</p>\r\n  </body>\r\n</html>\r\n"
        XCTAssertEqual(html.extractTextFromHTML(respectNewLines: false), "HTML! Yes!")

        html = "<html>\r\n  <head>\r\n\r\n"
            + "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\r\n"
            + "</head>\r\n  <body bgcolor=\"#FFFFFF\" text=\"#000000\">\r\n"
            + "<p>HTML! <b>Yes!</b><br>\r\n"
            + "</p><p>Whatever. New paragraph.</p>\r\n  </body>\r\n</html>\r\n"
        XCTAssertEqual(html.extractTextFromHTML(respectNewLines: false), "HTML! Yes! Whatever. New paragraph.")

        html = "<html>\r\n  <head>\r\n\r\n"
            + "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\r\n"
            + "</head>\r\n  <body bgcolor=\"#FFFFFF\" text=\"#000000\">\r\n"
            + "<p>HTML! <b>Yes!</b><br>\r\n"
            + "</p><p>Whatever. New <b>bold</b> paragraph.</p>\r\n  </body>\r\n</html>\r\n"
        XCTAssertEqual(
            html.extractTextFromHTML(respectNewLines: false), "HTML! Yes! Whatever. New bold paragraph.")
    }

    class TestMarkdownImageDelegate: MarkdownImageDelegate {
        var imgCount = 0

        func img(src: String, alt: String?) -> (String, String) {
            let result = ("src\(imgCount)", "alt\(imgCount)")
            imgCount += 1
            return result
        }
    }

    func testToMarkdown() {
        let imgDelegate = TestMarkdownImageDelegate()

        guard let data = MiscUtil.loadData(bundleClass: StringHTMLExtensionTests.self,
                                           fileName: "NSHTML_2017-08-09 15_40_53 +0000.html") else {
            XCTFail()
            return
        }
        guard let inputString = String(data: data, encoding: String.Encoding.utf8) else {
            XCTFail()
            return
        }
        guard let mdString = inputString.attributedStringHtmlToMarkdown(
            imgDelegate: imgDelegate) else {
                XCTFail()
                return
        }
        XCTAssertTrue(mdString.count > 0)
        XCTAssertEqual(mdString, "2\n\n![alt0](src0)\n\n1\n\n![alt1](src1)\n\n\(pepSignatureTrimmed)")
        XCTAssertNotEqual(mdString, inputString)
    }

    // BUG IOS-2126
    // Test doesn't fullfill our expectations
    func testMarkdownToHtml() {
        let s1 = "Hi, what's up!"
        XCTAssertEqual(s1.markdownToHtml(), "<p>\(s1)</p>")

        let alt1 = "Image1"
        let ref1 = "cid:001"
        XCTAssertEqual("![\(alt1)](\(ref1))".markdownToHtml(),
                       "<p><img src=\"\(ref1)\" alt=\"\(alt1)\" /></p>")
    }

    // BUG IOS-2126
    func testMarkdownToHtmlNewLine() {
        let newLinePlainText = "\n"
        let newLineHtmlTag = "<br>"
        let s1 = "Hi, what's up!" + newLinePlainText
        let exp = "Hi, what's up!" + newLineHtmlTag
        XCTAssertEqual(s1.markdownToHtml(), "<p>\(exp)</p>")
    }

    // BUG IOS-2126
    func testMarkdownToHtmlTagBr() {
        let s1 = "\n\n"
        let sth = s1.markdownToHtml()
        XCTAssertEqual(sth, "<p><br><br></p>")
    }

    // BUG IOS-2126
    func testMarkdownToHtmlTab() {
        let s1 = "Hello World!\t"
        let sth = s1.markdownToHtml()
        XCTAssertEqual(sth, "<p>Hello World! </p>")
    }

    func testMarkdownMoreComplicated() {
        XCTAssertEqual(Constant.markdownString.markdownToHtml(), Constant.markdownAsHtmlString)
    }

    func testMarkdownToHtml5Spaces() {
        let s1 = "Hello 5(     ) spaces"
        XCTAssertEqual(s1.markdownToHtml(), "<p>\(s1)</p>")
    }

    func testExtractCid() {
        let token = "uiaeuiae"
        XCTAssertEqual("cid:\(token)".extractCid(), token)
        XCTAssertEqual("cid://\(token)".extractCid(), token)
        XCTAssertNil("file:\(token)".extractCid())
        XCTAssertNil(token.extractCid())
        XCTAssertNil("http://uiaeuiaeuiae".extractCid())
        XCTAssertNil("whatever is this".extractCid())
    }

    class AttachmentDelegate: HtmlToAttributedTextSaxParserAttachmentDelegate {
        let attachments: [Attachment]
        var numberOfAttachmentsUsed = 0

        init(attachments: [Attachment]) {
            self.attachments = attachments
        }

        func imageAttachment(src: String?, alt: String?) -> Attachment? {
            let attch = attachments[numberOfAttachmentsUsed]
            numberOfAttachmentsUsed += 1
            return attch
        }
    }
}

extension StringHTMLExtensionTests {
    private struct Constant {
        static let markdownString = """
Heading
=======

Sub-heading
-----------

Paragraphs are separated
by a blank line.

Two spaces at the end of a line
produces a line break.

Text attributes _italic_,
**bold**, `monospace`.

Horizontal rule:

---

Strikesomething:
~~strikesomething~~

Bullet list:

  * one
  * two
  * three

Numbered list:

  1. one
  2. two
  3. three
"""

        static let markdownAsHtmlString = "<p>Heading<br>=======<br><br>Sub-heading<br>-----------<br><br>Paragraphs are separated<br>by a blank line.<br><br>Two spaces at the end of a line<br>produces a line break.<br><br>Text attributes <em>italic</em>,<br><strong>bold</strong>, <code>monospace</code>.<br><br>Horizontal rule:<br><br>---<br><br>Strikesomething:<br>~~strikesomething~~<br><br>Bullet list:<br><br>  * one<br>  * two<br>  * three<br><br>Numbered list:<br><br>  1. one<br>  2. two<br>  3. three</p>";

    }
}
