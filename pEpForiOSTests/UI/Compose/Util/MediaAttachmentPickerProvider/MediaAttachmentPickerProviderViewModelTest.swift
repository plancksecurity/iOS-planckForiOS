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
    private var vm:  MediaAttachmentPickerProviderViewModel?
    private var resultDelegate:TestResultDelegate?

    // MARK: - init & resultDelegate

    func testInitAndResultDelegate() {
        let resultDelegate = TestResultDelegate(expDidSelectMediaAttachmentCalled: nil,
                                                expectedMediaAttachment: nil,
                                                expDidCancelCalled: nil)
            as MediaAttachmentPickerProviderViewModelResultDelegate
        let testeeVM = MediaAttachmentPickerProviderViewModel(resultDelegate: resultDelegate)
        XCTAssertNotNil(testeeVM)
        guard let testeeResultDelegate = testeeVM.resultDelegate else {
            XCTFail()
            return
        }
        XCTAssertTrue(testeeResultDelegate === resultDelegate)
    }

    // MARK: - test assert helper method

    func testAssertHelperMethod() {
        assert(didSelectMediaAttachmentMustBeCalledCalled: nil,
               expectedMediaAttachment: nil,
               didCancelMustBeCalled: nil)
        XCTAssertNotNil(vm)
        guard let testeeResultDelegate = vm?.resultDelegate else {
            XCTFail()
            return
        }
        XCTAssertTrue(testeeResultDelegate === resultDelegate)
    }


    /*

             public func handleDidFinishPickingMedia(info: [String: Any]) {
             let isImage = (info[UIImagePickerControllerOriginalImage] as? UIImage) != nil
             if isImage {
             // We got an image.
             createImageAttchmentAndInformResultDelegate(info: info)
             } else {
             // We got something from picker that is not an image. Probalby video/movie.
             createMovieAttchmentAndInformResultDelegate(info: info)
             }
             }

     public func handleDidCancel() {
     resultDelegate?.mediaAttachmentPickerProviderViewModelDidCancel(self)
     }

     }

     // MARK: - MediaAttachment

     extension MediaAttachmentPickerProviderViewModel {
     struct MediaAttachment {
     enum MediaAttachmentType {
     case image
     case movie
     }
     let type: MediaAttachmentType
     let attachment: Attachment
     }
     */


    // MARK: - Helper

    private func assert(didSelectMediaAttachmentMustBeCalledCalled: Bool?,
                        expectedMediaAttachment: MediaAttachmentPickerProviderViewModel.MediaAttachment?,
                        didCancelMustBeCalled: Bool?) {
        var expDidSelectMediaAttachmentCalled: XCTestExpectation? = nil
        if let mustBeCalled = didSelectMediaAttachmentMustBeCalledCalled {
            expDidSelectMediaAttachmentCalled =
                expectation(named: "expDidSelectMediaAttachmentCalled",
                            inverted: mustBeCalled)
        }

        var expDidCancelCalled: XCTestExpectation? = nil
        if let mustBeCalled = didCancelMustBeCalled {
            expDidCancelCalled = expectation(named: "expDidCancelCalled",
                                             inverted: mustBeCalled)
        }


        resultDelegate =
            TestResultDelegate(expDidSelectMediaAttachmentCalled: expDidSelectMediaAttachmentCalled,
                               expectedMediaAttachment: expectedMediaAttachment,
                               expDidCancelCalled: expDidCancelCalled)
        vm = MediaAttachmentPickerProviderViewModel(resultDelegate: resultDelegate)
    }

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
