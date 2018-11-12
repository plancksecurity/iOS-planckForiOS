//
//  AttachmentViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 12.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//
import XCTest
@testable import pEpForiOS
import MessageModel

class AttachmentViewModelTest: XCTestCase {
//    lazy private var attachment: Attachment = {
//        return TestUtil.createAttachment(inlined: false)
//    }()
//    lazy private var vm: AttachmentViewModel = {
//        return AttachmentViewModel(attachment: attachment)
//    }()

    // MARK: - fileName

    func testFileName_nameGiven() {
        let attachment = TestUtil.createAttachment(inlined: false)
        let vm = AttachmentViewModel(attachment: attachment)
        let expected = attachment.fileName
        let testee = vm.fileName
        XCTAssertFalse(testee.isEmpty)
        XCTAssertEqual(testee, expected)
    }

    func testFileName_nameNotGiven() {
        let attachment = TestUtil.createAttachment(inlined: false)
        attachment.fileName = nil
        let vm = AttachmentViewModel(attachment: attachment)
        let expected = AttachmentViewModel.defaultFileName
        let testee = vm.fileName
        XCTAssertFalse(testee.isEmpty)
        XCTAssertEqual(testee, expected)
    }

    // MARK: - fileExtension

    func testFileExtension_have() {
        let attachment = TestUtil.createAttachment(inlined: false)
        XCTAssertEqual(attachment.mimeType, "image/jpeg")
        let vm = AttachmentViewModel(attachment: attachment)
        let expected = "jpg"
        let testee = vm.fileExtension
        XCTAssertEqual(testee, expected)
    }

    func testFileExtension_noHave() {
        let attachment = TestUtil.createAttachment(inlined: false)
        attachment.mimeType = "we should not have a mime type for this"
        let vm = AttachmentViewModel(attachment: attachment)
        let expected = ""
        let testee = vm.fileExtension
        XCTAssertEqual(testee, expected)
    }

    /*

     public let attachment: Attachment

     init(attachment: Attachment) {
     self.attachment = attachment
     }
     */
}
