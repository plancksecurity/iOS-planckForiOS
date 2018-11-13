//
//  MediaAttachmentPickerProviderViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 13.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//
import XCTest

@testable import pEpForiOS
import MessageModel

class MediaAttachmentPickerProviderViewModelTest: XCTestCase {

    // MARK: - Helper

    private class TestResultDelegate: MediaAttachmentPickerProviderViewModelResultDelegate {
        let expDidSelectMediaAttachmentCalled: XCTestExpectation?
        let expectedMediaAttachment: MediaAttachmentPickerProviderViewModel.MediaAttachment?

        let expDidCancelCalled: XCTestExpectation?

        init(expDidSelectMediaAttachmentCalled: XCTestExpectation?,
             expectedMediaAttachment: MediaAttachmentPickerProviderViewModel.MediaAttachment?,
             expDidCancelCalled: XCTestExpectation?) {
            self.expDidSelectMediaAttachmentCalled  = expDidSelectMediaAttachmentCalled
            self.expectedMediaAttachment = expectedMediaAttachment
            self.expDidCancelCalled = expDidCancelCalled
        }

        func mediaAttachmentPickerProviderViewModel(_ vm: MediaAttachmentPickerProviderViewModel, didSelect mediaAttachment: MediaAttachmentPickerProviderViewModel.MediaAttachment) {
                        guard let exp = expDidSelectMediaAttachmentCalled else {
                            // We ignore called or not
                            return
                        }
                        exp.fulfill()
                        if let expected = expectedMediaAttachment?.attachment {
                            XCTAssertEqual(mediaAttachment.attachment, expected)
                        }
        }

        func mediaAttachmentPickerProviderViewModelDidCancel(_ vm: MediaAttachmentPickerProviderViewModel) {
            guard let exp = expDidCancelCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }
    }
}
