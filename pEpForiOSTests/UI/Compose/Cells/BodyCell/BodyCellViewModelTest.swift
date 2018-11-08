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

    /*
     // PUBLIC API TO TEST

     public func inititalText() -> (text: String?, attributedText: NSAttributedString?) {
             if plaintext.isEmpty {
             plaintext.append(.pepSignature)
             }
             attributedText?.assureMaxTextAttachmentImageWidth(maxTextattachmentWidth)
             return (plaintext, attributedText)
             }

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
    let userWantsToAddMediaCalled: XCTestExpectation?
    let userWantsToAddDocumentCalled: XCTestExpectation?
    // inlined image
    let inlinedAttachmentsCaled: XCTestExpectation?
    let inlined: [Attachment]?

    func bodyCellViewModelTextChanged(_ vm: BodyCellViewModel) {
        fatalError()
    }

    func bodyCellViewModelUserWantsToAddMedia(_ vm: BodyCellViewModel) {
        guard let exp = userWantsToAddMediaCalled else {
            // We ignore called or not
            return
        }
        exp.fulfill()
//        delegate?.showMediaAttachmentPicker()
    }

    func bodyCellViewModelUserWantsToAddDocument(_ vm: BodyCellViewModel) {
        guard let exp = userWantsToAddDocumentCalled else {
            // We ignore called or not
            return
        }
        exp.fulfill()
//        delegate?.showDocumentAttachmentPicker()
    }

    func bodyCellViewModel(_ vm: BodyCellViewModel,
                           inlinedAttachmentsChanged inlinedAttachments: [Attachment]) {
        guard let exp = inlinedAttachmentsCaled else {
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
        fatalError()
//        state.bodyHtml = html
//        state.bodyPlaintext = plain
    }
}
