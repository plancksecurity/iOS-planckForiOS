//
//  BodyCellViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 08.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class BodyCellViewModelTest: CoreDataDrivenTestBase {
    var vm: BodyCellViewModel!
    var testDelegate: TestBodyCellViewModelDelegate?
    var testResultDelegate: TestBodyCellViewModelResultDelegate?

    // MARK: - inititalText

    func testInititalText_plain() {
        let intitialPlain = "intitial text"
        setupAssertionDelegates(initialPlaintext: intitialPlain, initialAttributedText: nil, inlinedAttachments: nil)
        let (text, _) = vm.inititalText()
        guard let testee = text else {
            XCTFail()
            return
        }
        XCTAssertEqual(testee, intitialPlain)
    }

    func testInititalText_html() {
        let intitialHtml = NSAttributedString(string: "intitial text")
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: intitialHtml,
                                inlinedAttachments: nil)
        let (_, html) = vm.inititalText()
        guard let testee = html else {
            XCTFail()
            return
        }
        XCTAssertEqual(testee, intitialHtml)
    }

    func testInititalText_both() {
        let intitialPlain = "intitial text"
        let initialHtml = NSAttributedString(string: "intitial text")
        setupAssertionDelegates(initialPlaintext: intitialPlain,
                                initialAttributedText: initialHtml,
                                inlinedAttachments: nil)
        let (text, html) = vm.inititalText()
        guard let testee = text else {
            XCTFail()
            return
        }
        guard let testeeHtml = html else {
            XCTFail()
            return
        }
        XCTAssertEqual(testee, intitialPlain)
        XCTAssertEqual(testeeHtml, initialHtml)
    }

    func testInititalText_noHtml() {
        let intitialPlain = "intitial text"
        setupAssertionDelegates(initialPlaintext: intitialPlain, initialAttributedText: nil, inlinedAttachments: nil)
        let (_, html) = vm.inititalText()
        XCTAssertNil(html)
    }

    func testInititalText_signatureSet() {
        let intitialHtml = NSAttributedString(string: "intitial text")
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: intitialHtml,
                                inlinedAttachments: nil)
        let (text, _) = vm.inititalText()
        XCTAssertEqual(text, .pepSignature)
    }

    func testInititalText_emptyInit_signatureSet() {
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                inlinedAttachments: nil)
        let (text, _) = vm.inititalText()
        XCTAssertEqual(text, .pepSignature)
    }


    /*
     // PUBLIC API TO TEST

     public func handleTextChange(newText: String, newAttributedText attrText: NSAttributedString) {
             plaintext = newText
             attributedText = attrText
             createHtmlVersionAndInformDelegate(newAttributedText: attrText)
             resultDelegate?.bodyCellViewModel(self, textChanged: newText)
             }

     public func shouldReplaceText(in range: NSRange, of text: NSAttributedString, with replaceText: String) -> Bool {
             let attachments = text.textAttachments(range: range)
             .map { $0.attachment }
             .compactMap { $0 }
             removeInlinedAttachments(attachments)
             return true
             }

     // MARK: - Context Menu

     public func handleUserClickedSelectMedia() {
             let potentialImage = 1
             rememberCursorPosition(offset: potentialImage)
             resultDelegate?.bodyCellViewModelUserWantsToAddMedia(self)
             }

     public func handleUserClickedSelectDocument() {
             rememberCursorPosition()
             resultDelegate?.bodyCellViewModelUserWantsToAddDocument(self)
             }
             }

     // MARK: - Cursor Position / Selection

     public func handleCursorPositionChange(newPosition: Int) {
             lastKnownCursorPosition = newPosition
             }


     // MARK: - Attachments

     public func inline(attachment: Attachment) {
     */

    // MARK: - Helpers

    private func setupAssertionDelegates(
        initialPlaintext: String?, initialAttributedText: NSAttributedString?, inlinedAttachments: [Attachment]?,
        expectInsertCalled: XCTestExpectation? = nil, inserted: NSAttributedString? = nil,

        expUserWantsToAddMediaCalled: XCTestExpectation? = nil,
        expUserWantsToAddDocumentCalled: XCTestExpectation? = nil,
        expInlinedAttachmentsCaled: XCTestExpectation? = nil, inlined: [Attachment]? = nil,
        expBodyChangedCalled: XCTestExpectation? = nil, exectedPlain: String? = nil, exectedHtml: String? = nil) {
        // Delegate
        testDelegate = TestBodyCellViewModelDelegate(expectInsertCalled: expectInsertCalled, inserted: inserted)

        // Result Delegate
        let newTestResultDelegate =
            TestBodyCellViewModelResultDelegate(
                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled, expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled,
                expInlinedAttachmentsCaled: expInlinedAttachmentsCaled, inlined: inlined,
                expBodyChangedCalled: expBodyChangedCalled, exectedPlain: exectedPlain, exectedHtml: exectedHtml)
        testResultDelegate = newTestResultDelegate
        vm = BodyCellViewModel(resultDelegate: newTestResultDelegate,
                               initialPlaintext: initialPlaintext,
                               initialAttributedText: initialAttributedText,
                               inlinedAttachments: inlinedAttachments)
        vm.delegate = testDelegate
    }

}

class TestBodyCellViewModelDelegate: BodyCellViewModelDelegate {
    //insert
    let expectInsertCalled: XCTestExpectation?
    let inserted: NSAttributedString?

    init(expectInsertCalled: XCTestExpectation?, inserted: NSAttributedString?) {
        self.expectInsertCalled = expectInsertCalled
        self.inserted = inserted
    }

    // BodyCellViewModelDelegate

    func insert(text: NSAttributedString) {
        guard let exp = expectInsertCalled else {
            // We ignore called or not
            return
        }
        exp.fulfill()
        if let expected = inserted {
            XCTAssertEqual(text, expected)
        }
    }
}

// MARK: BodyCellViewModelResultDelegate

class TestBodyCellViewModelResultDelegate: BodyCellViewModelResultDelegate {
    // context menu
    let expUserWantsToAddMediaCalled: XCTestExpectation?
    let expUserWantsToAddDocumentCalled: XCTestExpectation?
    // inlined image
    let expInlinedAttachmentsCaled: XCTestExpectation?
    let inlined: [Attachment]?
    // content change
    let expBodyChangedCalled: XCTestExpectation?
    let exectedPlain: String?
    let exectedHtml: String?

    init(expUserWantsToAddMediaCalled: XCTestExpectation?,
         expUserWantsToAddDocumentCalled: XCTestExpectation?,
         expInlinedAttachmentsCaled: XCTestExpectation?, inlined: [Attachment]?,
         expBodyChangedCalled: XCTestExpectation?, exectedPlain: String?, exectedHtml: String?) {
        self.expUserWantsToAddMediaCalled = expUserWantsToAddMediaCalled
        self.expUserWantsToAddDocumentCalled = expUserWantsToAddDocumentCalled
        self.expInlinedAttachmentsCaled = expInlinedAttachmentsCaled
        self.inlined = inlined
        self.expBodyChangedCalled = expBodyChangedCalled
        self.exectedPlain = exectedPlain
        self.exectedHtml = exectedHtml
    }

    func bodyCellViewModelUserWantsToAddMedia(_ vm: BodyCellViewModel) {
        guard let exp = expUserWantsToAddMediaCalled else {
            // We ignore called or not
            return
        }
        exp.fulfill()
//        delegate?.showMediaAttachmentPicker()
    }

    func bodyCellViewModelUserWantsToAddDocument(_ vm: BodyCellViewModel) {
        guard let exp = expUserWantsToAddDocumentCalled else {
            // We ignore called or not
            return
        }
        exp.fulfill()
//        delegate?.showDocumentAttachmentPicker()
    }

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           inlinedAttachmentsChanged inlinedAttachments: [Attachment]) {
        guard let exp = expInlinedAttachmentsCaled else {
            // We ignore called or not
            return
        }
        exp.fulfill()
        if let expected = inlined {
            XCTAssertEqual(inlinedAttachments.count, expected.count)
            for testee in inlinedAttachments {
                XCTAssertTrue(expected.contains(testee))
            }
        }
//        state.inlinedAttachments = inlinedAttachments
//        delegate?.hideMediaAttachmentPicker()
    }

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           bodyChangedToPlaintext plain: String,
                           html: String) {
        guard let exp = expBodyChangedCalled else {
            // We ignore called or not
            return
        }
        exp.fulfill()
        if let expected1 = exectedPlain {
            XCTAssertEqual(plain, expected1)
        }
        if let expected2 = exectedHtml {
            XCTAssertEqual(html, expected2)
        }
//        state.bodyHtml = html
//        state.bodyPlaintext = plain
    }
}
