//
//  StringHTMLExtensionTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class StringHTMLExtensionTests: XCTestCase {
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
        XCTAssertEqual(html.extractTextFromHTML(), "HTML! Yes! Whatever. New paragraph.")

        html = "<html>\r\n  <head>\r\n\r\n"
            + "<meta http-equiv=\"content-type\" content=\"text/html; charset=utf-8\">\r\n"
            + "</head>\r\n  <body bgcolor=\"#FFFFFF\" text=\"#000000\">\r\n"
            + "<p>HTML! <b>Yes!</b><br>\r\n"
            + "</p><p>Whatever. New <b>bold</b> paragraph.</p>\r\n  </body>\r\n</html>\r\n"
        XCTAssertEqual(
            html.extractTextFromHTML(), "HTML! Yes! Whatever. New bold paragraph.")
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
        XCTAssertEqual(mdString, "2\n\n![alt0](src0)\n\n1\n\n![alt1](src1)\n\nSent with p≡p")
        XCTAssertNotEqual(mdString, inputString)
    }

    func testMarkdownToHtml() {
        let s1 = "Hi, what's up!"
        XCTAssertEqual(s1.markdownToHtml(), "<p>\(s1)</p>\n")

        let alt1 = "Image1"
        let ref1 = "cid:001"
        XCTAssertEqual("![\(alt1)](\(ref1))".markdownToHtml(),
                       "<p><img src=\"\(ref1)\" alt=\"\(alt1)\" /></p>\n")
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

    /**
     Proves that we can convert primitive HTML with inline image references into an
     `NSAttributedString`, and that into markdown, while keeping the attachment's
     data and mime type intact.
     */
    func testRoundTrip() {
        let cid1 = "attached-inline-image-1-jpg-3A18D4C9-FA39-486F-AE80-65374C7E5880@pretty.Easy.privacy"
        let alt1 = "Attached Image 1 (jpg)"

        let theData = "Not an image".data(using: .utf8)
        let theMimeType = MimeTypeUtil.jpegMimeType
        let attachment = Attachment.create(
            data: theData, mimeType: theMimeType, fileName: "cid:\(cid1)",
            size: theData?.count)

        let input = "<p><img src=\"cid:\(cid1)\" alt=\"\(alt1)\" /></p>\n<p>Sent with p≡p</p>\n<p>Test 001 wrote on August 25, 2017 at 3:34:17 PM GMT+2:</p>\n<blockquote>\n<p>Just some mind the gap text.</p>\n<p>Blah!</p>\n</blockquote>\n"

        let attachmentDelegate = AttachmentDelegate(attachments: [attachment])
        let attributedString = input.htmlToAttributedString(attachmentDelegate: attachmentDelegate)
        XCTAssertEqual(
            attributedString.string,
            "\n￼\nSent with p≡p\nTest 001 wrote on August 25, 2017 at 3:34:17 PM GMT+2:\n> Just some mind the gap text.\n> Blah!")

        XCTAssertEqual(attachmentDelegate.numberOfAttachmentsUsed, 1)
        XCTAssertEqual(attachmentDelegate.attachments[0].mimeType, theMimeType)

        let (markdown, attachments) = attributedString.convertToMarkDown()
        XCTAssertEqual(attachments.count, 1)

        let patternImage = "!\\[[^]]+]\\([^)]+\\)"
        let patternRest1 = "\nSent with p≡p\n"
        let patternRest2 = "Test 001 wrote on August 25, 2017 at 3:34:17 PM GMT\\+2:\n"
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
