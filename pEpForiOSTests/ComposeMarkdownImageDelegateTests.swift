//
//  ComposeMarkdownImageDelegateTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 14.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

class ComposeMarkdownImageDelegateTests: XCTestCase {
    func testToMarkdown() {
        let attachments = [
            Attachment.create(data: nil, mimeType: "image/jpeg", fileName: "Attach_001.jpg"),
            Attachment.create(data: nil, mimeType: "image/jpeg", fileName: "Attach_002.jpg"),
        ]
        let imgDelegate = ComposeMarkdownImageDelegate(attachments: attachments)
        XCTAssertEqual(imgDelegate.attachments.count, attachments.count)

        guard let data = TestUtil.loadData(fileName: "NSHTML_2017-08-09 15_40_53 +0000.html") else {
            XCTFail()
            return
        }
        guard let inputString = String(data: data, encoding: String.Encoding.utf8) else {
            XCTFail()
            return
        }
        guard let mdString = inputString.htmlToSimpleMarkdown(imgDelegate: imgDelegate) else {
            XCTFail()
            return
        }
        XCTAssertTrue(mdString.characters.count > 0)
        XCTAssertEqual(imgDelegate.attachmentInfos.count, imgDelegate.attachments.count)

        let alt0 = imgDelegate.attachmentInfos[0].alt
        let cid0 = imgDelegate.attachmentInfos[0].cidUrl
        let alt1 = imgDelegate.attachmentInfos[1].alt
        let cid1 = imgDelegate.attachmentInfos[1].cidUrl

        XCTAssertTrue(alt0.hasExtension("jpg"))
        XCTAssertTrue(cid0.hasExtension("jpg"))
        XCTAssertTrue(alt1.hasExtension("jpg"))
        XCTAssertTrue(cid1.hasExtension("jpg"))

        XCTAssertEqual(mdString, "2\n![\(alt0)](\(cid0))]\n1\n![\(alt1)](\(cid1))]\nSent with p≡p")
        XCTAssertNotEqual(mdString, inputString)
    }
}
