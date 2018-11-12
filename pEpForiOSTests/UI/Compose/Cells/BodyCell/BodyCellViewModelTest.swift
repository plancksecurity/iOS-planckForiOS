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
        setupAssertionDelegates(initialPlaintext: intitialPlain, initialAttributedText: nil, initialInlinedAttachments: nil)
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
                                initialInlinedAttachments: nil)
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
                                initialInlinedAttachments: nil)
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
        setupAssertionDelegates(initialPlaintext: intitialPlain, initialAttributedText: nil, initialInlinedAttachments: nil)
        let (_, html) = vm.inititalText()
        XCTAssertNil(html)
    }

    func testInititalText_signatureSet() {
        let intitialHtml = NSAttributedString(string: "intitial text")
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: intitialHtml,
                                initialInlinedAttachments: nil)
        let (text, _) = vm.inititalText()
        XCTAssertEqual(text, .pepSignature)
    }

    func testInititalText_emptyInit_signatureSet() {
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil)
        let (text, _) = vm.inititalText()
        XCTAssertEqual(text, .pepSignature)
    }

    // MARK: - Initial Inlined Attachents

    func testInitialAttachments() {
        let inlinedAttachments = testAttachments(numAttachments: 1)
        let expInlinedAttachmentsChangeNotCalledWhenInitializing =
            expInlinedAttachmentChanged(mustBeCalled: false)

        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: inlinedAttachments,
                                expectInsertCalled: nil,
                                inserted: nil,
                                expUserWantsToAddMediaCalled: nil,
                                expUserWantsToAddDocumentCalled: nil,
                                expInlinedAttachmentsCalled: expInlinedAttachmentsChangeNotCalledWhenInitializing,
                                inlined: nil,
                                expBodyChangedCalled: nil,
                                exectedPlain: nil,
                                exectedHtml: nil)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - handleTextChange

    func testHandleTextChange() {
        let newPlainText = "testPlainText"
        let newAttributedContent = "testAttributedText"
        let newAttributedText = NSAttributedString(string: newAttributedContent)

        let attributedTextWins = newAttributedContent
        let expectedPlainText = attributedTextWins
        let expectedHtml = htmlVersion(of: newAttributedContent)

        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: nil,
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: false),
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: true),
                                exectedPlain: expectedPlainText,
                                exectedHtml: expectedHtml)
        vm.handleTextChange(newText: newPlainText, newAttributedText: newAttributedText)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleTextChange_initialTextSet() {
        let initText = "initText"
        let initAttributedText = NSAttributedString(string: "initAttributedText")

        let newPlainText = "testPlainText"
        let newAttributedContent = "testAttributedText"
        let newAttributedText = NSAttributedString(string: newAttributedContent)

        let attributedTextWins = newAttributedContent

        let expectedPlainText = attributedTextWins
        let expectedHtml = htmlVersion(of: newAttributedContent)

        setupAssertionDelegates(initialPlaintext: initText,
                                initialAttributedText: initAttributedText,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: nil,
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: false),
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: true),
                                exectedPlain: expectedPlainText,
                                exectedHtml: expectedHtml)
        vm.handleTextChange(newText: newPlainText, newAttributedText: newAttributedText)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleTextChange_emptyString() {
        let newPlainText = ""
        let newAttributedContent = ""
        let newAttributedText = NSAttributedString(string: newAttributedContent)

        let attributedTextWins = newAttributedContent
        let expectedPlainText = attributedTextWins
        let expectedHtml = htmlVersion(of: newAttributedContent)

        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: nil,
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: false),
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: true),
                                exectedPlain: expectedPlainText,
                                exectedHtml: expectedHtml)
        vm.handleTextChange(newText: newPlainText, newAttributedText: newAttributedText)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleTextChange_notCalled() {
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: nil,
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: false),
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        // We do not call handleTextChange, so no callback should be called.
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - inline(attachment:

    func testInlineAttachment_called() {
        let attachment = testAttachment(addImage: true)
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: true),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: nil,
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: true),
                                inlined: [attachment],
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        let nonZeroValue: CGFloat = 300.0
        vm.maxTextattachmentWidth = nonZeroValue
        vm.inline(attachment: attachment)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testInlineAttachment_notCalled() {
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: nil,
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: false),
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        let nonZeroValue: CGFloat = 300.0
        vm.maxTextattachmentWidth = nonZeroValue
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - shouldReplaceText(in range:of text:with replaceText:)

    func shouldReplaceText() {
        let testText = NSAttributedString(string: "Test text")
        let testTextAttachment = testAttachment(addImage: true)

        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: nil,
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: false),
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        let nonZeroValue: CGFloat = 300.0
        vm.maxTextattachmentWidth = nonZeroValue
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    /*
     // PUBLIC API TO TEST

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
 */

    // MARK: - Helpers

    private func setupAssertionDelegates(
        initialPlaintext: String? = nil, initialAttributedText: NSAttributedString? = nil, initialInlinedAttachments: [Attachment]? = nil,
        expectInsertCalled: XCTestExpectation? = nil, inserted: NSAttributedString? = nil,

        expUserWantsToAddMediaCalled: XCTestExpectation? = nil,
        expUserWantsToAddDocumentCalled: XCTestExpectation? = nil,
        expInlinedAttachmentsCalled: XCTestExpectation? = nil, inlined: [Attachment]? = nil,
        expBodyChangedCalled: XCTestExpectation? = nil, exectedPlain: String? = nil, exectedHtml: String? = nil) {
        // Delegate
        testDelegate = TestBodyCellViewModelDelegate(expectInsertCalled: expectInsertCalled, inserted: inserted)

        // Result Delegate
        let newTestResultDelegate =
            TestBodyCellViewModelResultDelegate(
                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled, expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled,
                expInlinedAttachmentsCalled: expInlinedAttachmentsCalled, inlined: inlined,
                expBodyChangedCalled: expBodyChangedCalled, exectedPlain: exectedPlain, exectedHtml: exectedHtml)
        testResultDelegate = newTestResultDelegate
        vm = BodyCellViewModel(resultDelegate: newTestResultDelegate,
                               initialPlaintext: initialPlaintext,
                               initialAttributedText: initialAttributedText,
                               inlinedAttachments: initialInlinedAttachments)
        vm.delegate = testDelegate
    }

    private func testAttachment(data: Data? = nil,
                                mimeType: String = "test/mimeType",
                                fileName: String? = nil,
                                size: Int? = nil,
                                url: URL? = nil,
                                addImage: Bool = false,
                                assetUrl: URL? = nil,
                                contentDisposition: Attachment.ContentDispositionType = .inline) -> Attachment {
        guard let att = testAttachments(numAttachments: 1,
                                        data: data,
                                        mimeType: mimeType,
                                        fileName: fileName,
                                        size: size,
                                        url: url,
                                        addImage: addImage,
                                        assetUrl: assetUrl,
                                        contentDisposition: contentDisposition).first else {
            XCTFail()
            return Attachment(data: Data(), mimeType: "", contentDisposition: .other)
        }
        return att
    }

    private func testAttachments(numAttachments: Int = 1,
                                 data: Data? = nil,
                                 mimeType: String = "test/mimeType",
                                 fileName: String? = nil,
                                 size: Int? = nil,
                                 url: URL? = nil,
                                 addImage: Bool = false,
                                 assetUrl: URL? = nil,
                                 contentDisposition: Attachment.ContentDispositionType = .inline)
        -> [Attachment] {
            var attachments = [Attachment]()
            let imageFileName = "PorpoiseGalaxy_HubbleFraile_960.jpg" //IOS-1399: move to Utils
            guard
                let imageData = TestUtil.loadData(fileName: imageFileName),
                let image = UIImage(data: imageData) else {
                    XCTFail("No img")
                    return []
            }

            for i in 0..<numAttachments {
                attachments.append(Attachment(data: data,
                                              mimeType: mimeType,
                                              fileName: "\(i)",
                    size: size,
                    url: url,
                    image: addImage ? image : nil,
                    assetUrl: assetUrl,
                    contentDisposition: contentDisposition))
            }
            return attachments
    }

    private func htmlVersion(of string: String) -> String {
        return string.isEmpty ? string : "<p>" + string + "</p>" + "\n"
    }

    private func expInsertTextCalled(mustBeCalled: Bool) -> XCTestExpectation {
        return expectation(inverted: !mustBeCalled)
    }

    private func expUserWantsToAddMediaCalled(mustBeCalled: Bool) -> XCTestExpectation {
        return expectation(inverted: !mustBeCalled)
    }

    private func expUserWantsToAddDocumentCalled(mustBeCalled: Bool) -> XCTestExpectation {
        return expectation(inverted: !mustBeCalled)
    }

    private func expInlinedAttachmentChanged(mustBeCalled: Bool) -> XCTestExpectation {
        return expectation(inverted: !mustBeCalled)
    }

    private func expBodyChangedCalled(mustBeCalled: Bool) -> XCTestExpectation {
        return expectation(inverted: !mustBeCalled)
    }

    //!!!: Move to Utils
    private func expectation(named name: String = #function, inverted: Bool = false) -> XCTestExpectation {
        let description = name + " \(inverted)"
        let createe = expectation(description: description)
        createe.isInverted = inverted
        return createe
    }

    //MOVE:
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
    let expInlinedAttachmentsCalled: XCTestExpectation?
    let inlined: [Attachment]?
    // content change
    let expBodyChangedCalled: XCTestExpectation?
    let exectedPlain: String?
    let exectedHtml: String?

    init(expUserWantsToAddMediaCalled: XCTestExpectation?,
         expUserWantsToAddDocumentCalled: XCTestExpectation?,
         expInlinedAttachmentsCalled: XCTestExpectation?, inlined: [Attachment]?,
         expBodyChangedCalled: XCTestExpectation?, exectedPlain: String?, exectedHtml: String?) {
        self.expUserWantsToAddMediaCalled = expUserWantsToAddMediaCalled
        self.expUserWantsToAddDocumentCalled = expUserWantsToAddDocumentCalled
        self.expInlinedAttachmentsCalled = expInlinedAttachmentsCalled
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
        guard let exp = expInlinedAttachmentsCalled else {
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
