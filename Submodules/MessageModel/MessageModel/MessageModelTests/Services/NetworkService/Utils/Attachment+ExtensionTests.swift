//
//  Attachment+ExtensionTests.swift
//  MessageModelTests
//
//  Created by Alejandro Gelos on 26/06/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel

class Attachment_ExtensionTests: PersistentStoreDrivenTestBase {

    func testIsViewableWithInlinePlainText() {
        // GIVEN
        let attachmentTest = TestUtil.createAttachmentNamed()
        attachmentTest.data = Data()
        attachmentTest.mimeType = ContentTypeUtils.ContentType.plainText
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
        attachmentTest.mimeType = ContentTypeUtils.ContentType.pgpKeys

        // WHEN
        let isViewable = attachmentTest.isViewable()

        // THEN
        XCTAssertFalse(isViewable)
    }

    func testIsViewableWithPGP() {
        // GIVEN
        let attachmentTest = TestUtil.createAttachment()
        attachmentTest.data = Data()
        attachmentTest.mimeType = MimeTypeUtils.MimesType.pgp

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
