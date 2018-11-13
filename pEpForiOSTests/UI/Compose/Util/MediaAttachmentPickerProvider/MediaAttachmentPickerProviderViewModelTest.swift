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

    // MARK: - handleDidFinishPickingMedia

    // MARK: Photo

    func testHandleDidFinishPickingMedia_photo() {
        guard let (infoDict, forAttachment) = infoDict(mediaType: .image) else {
            XCTFail()
            return
        }
        assert(didSelectMediaAttachmentMustBeCalledCalled: true,
               expectedMediaAttachment: forAttachment,
               didCancelMustBeCalled: false)
        vm?.handleDidFinishPickingMedia(info: infoDict)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleDidFinishPickingMedia_photo_notCalled() {
        assert(didSelectMediaAttachmentMustBeCalledCalled: false,
               expectedMediaAttachment: nil,
               didCancelMustBeCalled: false)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: Video

    func testHandleDidFinishPickingMedia_movie() {
        guard let (infoDict, forAttachment) = infoDict(mediaType: .movie) else {
            XCTFail()
            return
        }
        assert(didSelectMediaAttachmentMustBeCalledCalled: true,
               expectedMediaAttachment: forAttachment,
               didCancelMustBeCalled: false)
        vm?.handleDidFinishPickingMedia(info: infoDict)
        waitForExpectations(timeout: 0.5) // Async file access
    }

    // MARK: - handleDidCancel

    func testHandleDidCancel() {
        assert(didSelectMediaAttachmentMustBeCalledCalled: false,
               expectedMediaAttachment: nil,
               didCancelMustBeCalled: true)
        vm?.handleDidCancel()
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleDidCancel_notCalled() {
        assert(didSelectMediaAttachmentMustBeCalledCalled: false,
               expectedMediaAttachment: nil,
               didCancelMustBeCalled: false)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - Helper

    private func assert(didSelectMediaAttachmentMustBeCalledCalled: Bool?,
                        expectedMediaAttachment: MediaAttachmentPickerProviderViewModel.MediaAttachment?,
                        didCancelMustBeCalled: Bool?) {
        var expDidSelectMediaAttachmentCalled: XCTestExpectation? = nil
        if let mustBeCalled = didSelectMediaAttachmentMustBeCalledCalled {
            expDidSelectMediaAttachmentCalled =
                expectation(named: "expDidSelectMediaAttachmentCalled",
                            inverted: !mustBeCalled)
        }

        var expDidCancelCalled: XCTestExpectation? = nil
        if let mustBeCalled = didCancelMustBeCalled {
            expDidCancelCalled = expectation(named: "expDidCancelCalled",
                                             inverted: !mustBeCalled)
        }


        resultDelegate =
            TestResultDelegate(expDidSelectMediaAttachmentCalled: expDidSelectMediaAttachmentCalled,
                               expectedMediaAttachment: expectedMediaAttachment,
                               expDidCancelCalled: expDidCancelCalled)
        vm = MediaAttachmentPickerProviderViewModel(resultDelegate: resultDelegate)
    }

    private func infoDict(mediaType: MediaAttachmentPickerProviderViewModel.MediaAttachment.MediaAttachmentType)
        -> (infoDict: [String: Any], forAttachment: MediaAttachmentPickerProviderViewModel.MediaAttachment)? {
            var createe = [String:Any]()
            let testBundle = Bundle(for: type(of:self))
            let imageFileName = "PorpoiseGalaxy_HubbleFraile_960.jpg" //IOS-1399: move to Utils
            guard let keyPath = testBundle.path(forResource: imageFileName, ofType: nil) else {
                XCTFail()
                return nil
            }
            let url = URL(fileURLWithPath: keyPath)
            guard
                let data = try? Data(contentsOf: url),
                let img = UIImage(data: data)
                else {
                    XCTFail()
                    return nil
            }

            if mediaType == .movie {
                createe[UIImagePickerControllerMediaURL] = url
            } else {
                createe[UIImagePickerControllerReferenceURL] = url
                createe[UIImagePickerControllerOriginalImage] = img
            }
            let attachment = Attachment(data: data,
                                        mimeType: "image/jpeg",
                                        fileName:
                "I have no idea what file name is actually expecdted, thus I ignore it in tests.",
                                        size: data.count, url: nil,
                                        image: img,
                                        assetUrl: url,
                                        contentDisposition: .inline)
            let mediaAttachment =
                MediaAttachmentPickerProviderViewModel.MediaAttachment(type: mediaType,
                                                                       attachment: attachment)
            return (createe, mediaAttachment)
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
            if let expected = expectedMediaAttachment{
                if let _ = mediaAttachment.attachment.image {
                    XCTAssertTrue(mediaAttachment.type == .image)
                    XCTAssertEqual(mediaAttachment.attachment.image, expected.attachment.image)
                } else {
                    XCTAssertTrue(mediaAttachment.type == .movie)
                    XCTAssertEqual(mediaAttachment.attachment.data, expected.attachment.data)
                }
                XCTAssertEqual(mediaAttachment.attachment.mimeType, expected.attachment.mimeType)
                //"I have no idea what file name is actually expecdted, thus I ignore it in tests."
                XCTAssertEqual(mediaAttachment.type, expected.type)
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
