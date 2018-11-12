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

    /*
     public var fileExtension: String {
     return mimeTypeUtil?.fileExtension(mimeType: attachment.mimeType) ?? ""
     }

     public let attachment: Attachment

     init(attachment: Attachment) {
     self.attachment = attachment
     }
     */
}
