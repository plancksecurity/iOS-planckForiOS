//
//  Attachment+ExtensionTests.swift
//  MessageModelTests
//
//  Created by Alejandro Gelos on 26/06/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
import pEpIOSToolbox

class Attachment_ExtensionTests: PersistentStoreDrivenTestBase {

    func testIsViewableWithInlinePlainText() {
        // GIVEN
        let attachmentTest = TestUtil.createAttachmentNamed()
        attachmentTest.data = Data()
        attachmentTest.mimeType = MimeTypeUtils.MimeType.plainText.rawValue
        attachmentTest.contentDisposition = .inline

        // WHEN
        let isViewable = attachmentTest.isViewable()

        // THEN
        XCTAssertFalse(isViewable)
    }

    func testIsViewableWithInline() {
        // GIVEN
        let attachmentTest = TestUtil.createAttachment()
        attachmentTest.data = Data()
        attachmentTest.contentDisposition = .inline

        // WHEN
        let isViewable = attachmentTest.isViewable()

        // THEN
        XCTAssertTrue(isViewable)
    }

    func testIsViewableWithPGPKey() {
        // GIVEN
        let attachmentTest = TestUtil.createAttachment()
        attachmentTest.data = Data()
        attachmentTest.mimeType = MimeTypeUtils.MimeType.pgpKeys.rawValue

        // WHEN
        let isViewable = attachmentTest.isViewable()

        // THEN
        XCTAssertFalse(isViewable)
    }

    func testIsViewableWithPGP() {
        // GIVEN
        let attachmentTest = TestUtil.createAttachment()
        attachmentTest.data = Data()
        attachmentTest.mimeType = MimeTypeUtils.MimeType.pgp.rawValue

        // WHEN
        let isViewable = attachmentTest.isViewable()

        // THEN
        XCTAssertFalse(isViewable)
    }

    func testIsViewable() {
        // GIVEN
        let attachmentTest = TestUtil.createAttachment()
        attachmentTest.data = Data()

        // WHEN
        let isViewable = attachmentTest.isViewable()

        // THEN
        XCTAssertTrue(isViewable)
    }

}
