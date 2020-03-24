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

        guard let data = TestUtil.loadData(fileName: "NSHTML_2017-08-09 15_40_53 +0000.html") else {
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

    func testHtmlInjection() {

        let src = """
        <html>\n  <head>\n   </head>\n  <body text=\"#000000\" bgcolor=\"#FFFFFF\">\n    <p><br></p>\n    <div class=\"moz-cite-prefix\">On 13/03/2020 14:59,\n      <a class=\"moz-txt-link-abbreviated\" href=\"mailto:iostest017@peptest.ch\">iostest017@peptest.ch</a> wrote:<br>\n    </div>\n    <blockquote type=\"cite\"\n      cite=\"mid:21d07f32-b8dd-d0c9-5066-35f4f14ad7d5@peptest.ch\">\n    \n      <p>Again<br>\n      </p>\n    </blockquote>\n    Comment1<br>\n    <blockquote type=\"cite\"\n      cite=\"mid:21d07f32-b8dd-d0c9-5066-35f4f14ad7d5@peptest.ch\">\n      <p> </p>\n      <div class=\"moz-cite-prefix\">On 13/03/2020 14:20, iostest018\n        wrote:<br>\n      </div>\n      <blockquote type=\"cite\"\n        cite=\"mid:ca880105-6e34-ecf3-c8cc-c542191ac4fd@peptest.ch\">\n               <p><br>\n        </p>\n      </blockquote>\n    </blockquote>\n    Comment2<br>\n    <blockquote type=\"cite\"\n      cite=\"mid:21d07f32-b8dd-d0c9-5066-35f4f14ad7d5@peptest.ch\">\n      <blockquote type=\"cite\"\n        cite=\"mid:ca880105-6e34-ecf3-c8cc-c542191ac4fd@peptest.ch\">\n        <p> </p>\n        <div class=\"moz-cite-prefix\">On 13/03/2020 11:35, iostest018\n          wrote:<br>\n        </div>\n        <blockquote type=\"cite\"\n          cite=\"mid:6ddb0381-d4ce-fe15-0bb9-3a38eb6a5f9f@peptest.ch\">\n                  <blockquote style=\"border-left: 2px solid #03AA4B; padding-left: 8px; margin-left:0px;\">Hello</p>\n        </blockquote>\n      </blockquote>\n    </blockquote>\n    Comment 3<br>\n    < type=\"cite\"\n      cite=\"mid:21d07f32-b8dd-d0c9-5066-35f4f14ad7d5@peptest.ch\">\n      <blockquote type=\"cite\"\n        cite=\"mid:ca880105-6e34-ecf3-c8cc-c542191ac4fd@peptest.ch\">\n        <blockquote type=\"cite\"\n          cite=\"mid:6ddb0381-d4ce-fe15-0bb9-3a38eb6a5f9f@peptest.ch\">\n          <p><font size=\"+3\" color=\"#cc0000\">Big red text</font></p>


            <p style="margin-left: 8px;"><font color=\"#aa00ff\">Sth </font>

        </p><p>Below should be inline picture attached</p>\n          <p><img moz-do-not-send=\"false\"             src=\"cid:part1.7D984609.4029FB7F@peptest.ch\" alt=\"This is\n              a png picutre. You should see it.\" class=\"\" width=\"98\"           height=\"110\"></p>        <p>Cheers</p><p>Test Monkey<br></p>          Added sth to text<br></blockquote>\n      </blockquote></blockquote></body></html>
        """.replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "<br>", with: "<br/>")

        let parser = HtmlTagParser(data: src.data(using: .utf16)!)
        let sth = String(parser.htmlString)

    }

    func testHtmlConvertImageLinksToImageBase64() {
        let src = """
        <div>
          <p>Taken from wikpedia</p>
          <img src="data:image/png;charset=utf-8;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA
            AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
                9TXL0Y4OHwAAAABJRU5ErkJggg==" alt="Red dot" />
        </div>
        """

        src.htmlConvertImageLinksToImageMarkdownString(html: src, attachmentDelegate: nil)
    }

    func testHtmlConvertImageBase64ToImageCidReference() {
        let cid = "cid:part1.7D984609.4029FB7F@peptest.ch"
        let src = """
        <div>
          <p>Taken from wikpedia</p>
          <img src="data:image/png;\(cid);charset=utf-8;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA
            AAAFCAYAAACNbyblAAAAHElEQVQI12P4//8/w38GIAXDIBKE0DHxgljNBAAO
                9TXL0Y4OHwAAAABJRU5ErkJggg==" alt="Red dot" />
        </div>
        """

        src.htmlConvertImageBase64ToImageCidReference(html: src)
        print(src)
    }

    /**
     Proves that we can convert primitive HTML with inline image references into an
     `NSAttributedString`, and that into markdown, while keeping the attachment's
     data and mime type intact.
     */
    func testRoundTrip() {
        let cid1 = "attached-inline-image-1-jpg-3A18D4C9-FA39-486F-AE80-65374C7E5880@pretty.Easy.privacy"
        let alt1 = "Attached Image 1 (jpg)"

        let theData = "Not an image".data(using: .utf8)
        let theMimeType = MimeTypeUtils.MimesType.jpeg
        let attachment = Attachment(data: theData,
                                    mimeType: theMimeType,
                                    fileName: "cid:\(cid1)",
            contentDisposition: .attachment)

        let attachmentHtml = "<p><img src=\"cid:\(cid1)\" alt=\"\(alt1)\" /></p>"
        let input = "\(attachmentHtml)\n<p>\(String.pEpSignatureHtml)</p>\n<p>Test 001 wrote on August 25, 2017 at 3:34:17 PM GMT+2:</p>\n<cite>\n<p>Just some mind the gap text.</p>\n<p>Blah!</p>\n</cite>\n"
        let inputWithoutAttachmentCiteTag = "<p>\(String.pEpSignatureHtml)</p>\n<p>Test 001 wrote on August 25, 2017 at 3:34:17 PM GMT+2:</p>\n<cite>\n<p>Just some mind the gap text.</p>\n<p>Blah!</p>\n</cite>\n"
        let inputWithoutAttachmentBlockquoteTag = "<p>\(String.pEpSignatureHtml)</p>\n<p>Test 001 wrote on August 25, 2017 at 3:34:17 PM GMT+2:</p>\n<blockquote>\n<p>Just some mind the gap text.</p>\n<p>Blah!</p>\n</blockquote>\n"

        let attachmentDelegate = AttachmentDelegate(attachments: [attachment])
        let attributedString = input.htmlToAttributedString(attachmentDelegate: attachmentDelegate)
        let sthWithCiteTag = inputWithoutAttachmentCiteTag.htmlToAttributedString(attachmentDelegate: nil).string
        let sthWithBlockquoteTag = inputWithoutAttachmentBlockquoteTag.htmlToAttributedString(attachmentDelegate: nil).string
        let exp = "\(pepSignatureTrimmed)\n\nTest 001 wrote on August 25, 2017 at 3:34:17 PM GMT+2:\n\n> Just some mind the gap text.\n> Blah!\n\n"
        XCTAssertEqual(sthWithCiteTag, exp)
        XCTAssertEqual(sthWithBlockquoteTag, exp)
        XCTAssertEqual(attachmentDelegate.numberOfAttachmentsUsed, 1)
        XCTAssertEqual(attachmentDelegate.attachments[0].mimeType, theMimeType)

        let (markdown, attachments) = attributedString.convertToMarkDown()
        XCTAssertEqual(attachments.count, 1)

        let patternImage = "!\\[[^]]+]\\([^)]+\\)"
        let patternRest1 = "\n\n\(pepSignatureTrimmed)\n\n"
        let patternRest2 = "Test 001 wrote on August 25, 2017 at 3:34:17 PM GMT\\+2:\n\n"
        let patternRest3 = "> Just some mind the gap text.\n> Blah!"
        XCTAssertTrue(markdown.matches(
            pattern: "^\(patternImage)\(patternRest1)\(patternRest2)\(patternRest3)$"))

        guard let attachmentNew = attachments.first else {
            XCTFail()
            return
        }
        XCTAssertEqual(attachmentNew.data, attachment.data)
        XCTAssertEqual(attachmentNew.mimeType, attachment.mimeType)
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
