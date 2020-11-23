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
import pEpIOSToolbox

class BodyCellViewModelTest: XCTestCase {
    var vm: BodyCellViewModel!
    private var testDelegate: TestDelegate?
    private var testResultDelegate: TestResultDelegate?

    // MARK: - inititalText

    func testInititalText_plain() {
        let intitialPlain = "intitial text"
        setupAssertionDelegates(initialPlaintext: intitialPlain,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil)
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
        setupAssertionDelegates(initialPlaintext: intitialPlain,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil)
        let (_, html) = vm.inititalText()
        XCTAssertNil(html)
    }

    // MARK: - Initial Inlined Attachents

    func testInitialAttachments() {
        let inlinedAttachments = createTestAttachments(numAttachments: 1)
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: inlinedAttachments,
                                expectInsertCalled: nil,
                                inserted: nil,
                                expUserWantsToAddMediaCalled: nil,
                                expUserWantsToAddDocumentCalled: nil,
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: false),
                                inlined: nil,
                                expBodyChangedCalled: nil,
                                exectedPlain: nil,
                                exectedHtml: nil)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - handleTextChange

    func testHandleTextChange_notCalled() {
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled(mustBeCalled: false),
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
        let attachment = createTestAttachment(addImage: true)
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: true),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled(mustBeCalled: false),
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
                                expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled(mustBeCalled: false),
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

    func testShouldReplaceText_noAttachment_replacetextEmpty() {
        let testText = NSAttributedString(string: "Test text")
        let testRange = NSRange(location: 0, length: "Test".count)
        let testReplaceText = ""

        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled(mustBeCalled: false),
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: false),
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        let shouldReplace = vm.shouldReplaceText(in: testRange, of: testText, with: testReplaceText)
        XCTAssertTrue(shouldReplace, "Should alway be true")
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testShouldReplaceText_noAttachment_replacetextNonEmpty() {
        let testText = NSAttributedString(string: "Test text")
        let testRange = NSRange(location: 0, length: "Test".count)
        let testReplaceText = "Replace"

        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled(mustBeCalled: false),
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: false),
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        let shouldReplace = vm.shouldReplaceText(in: testRange, of: testText, with: testReplaceText)
        XCTAssertTrue(shouldReplace, "Should alway be true")
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testShouldReplaceText_noAttachment_replacetextNewLine() {
        let testText = NSAttributedString(string: "Test text")
        let testRange = NSRange(location: 0, length: "Test".count)
        let testReplaceText = "\n"

        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled(mustBeCalled: false),
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: false),
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        let shouldReplace = vm.shouldReplaceText(in: testRange, of: testText, with: testReplaceText)
        XCTAssertTrue(shouldReplace, "Should alway be true")
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testShouldReplaceText_attachment_removeNone() {
        let textBuilder = NSAttributedString(string: "Test text")
        let replaceText = ""

        let insertRange = NSRange(location: "Test".count, length: 1)
        let testAttachment = createTestAttachment(addImage: true)
        let testText = insertTextattachment(for: testAttachment, in: insertRange, of: textBuilder)
        let testRange = NSRange(location: 0, length: "Test".count)
        XCTAssertTrue(testText.textAttachments(range: testRange).count == 0)

        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: [testAttachment],
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled(mustBeCalled: false),
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: false),
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        let shouldReplace = vm.shouldReplaceText(in: testRange, of: testText, with: replaceText)
        XCTAssertTrue(shouldReplace, "Should alway be true")
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testShouldReplaceText_attachment_removeAll() {
        var textBuilder = NSAttributedString(string: "Test text")
        let replaceText = ""
        let replaceRange = NSRange(location: 0, length: "Test".count)

        let testAttachment1 = createTestAttachment(addImage: true)
        textBuilder = insertTextattachment(for: testAttachment1, in: replaceRange, of: textBuilder)
        let testAttachment2 = createTestAttachment(addImage: true)
        let testText = insertTextattachment(for: testAttachment2, in: replaceRange, of: textBuilder)
        let attachmentRange = NSRange(location: 0, length: testText.length)
        XCTAssertTrue(testText.textAttachments(range: attachmentRange).count == 1)

        let expectNoAttachmentLeft = [Attachment]()

        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled(mustBeCalled: false),
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: true),
                                inlined: expectNoAttachmentLeft,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        let shouldReplace = vm.shouldReplaceText(in: attachmentRange, of: testText, with: replaceText)
        XCTAssertTrue(shouldReplace, "Should alway be true")
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testShouldReplaceText_attachment_removeOne() {
        var textBuilder = NSAttributedString(string: "Test text")
        let replaceText = ""
        let replaceRange = NSRange(location: 0, length: 0)

        let testAttachment1 = createTestAttachment(fileName: "1", addImage: true)
        textBuilder = insertTextattachment(for: testAttachment1, in: replaceRange, of: textBuilder)
        let testAttachment2 = createTestAttachment(fileName: "2", addImage: true)
        let testText = insertTextattachment(for: testAttachment2, in: replaceRange, of: textBuilder)
        let attachmentToRemoveRange = NSRange(location: 0, length: 1)

        let expectedAttachmentsLeft = [testAttachment1]
        XCTAssertTrue(testText.textAttachments(range: attachmentToRemoveRange).count == 1)

        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: [testAttachment1, testAttachment2],
                                expectInsertCalled: nil,
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled(mustBeCalled: false),
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: true),
                                inlined: expectedAttachmentsLeft,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        let shouldReplace = vm.shouldReplaceText(in: attachmentToRemoveRange,
                                                 of: testText,
                                                 with: replaceText)
        XCTAssertTrue(shouldReplace, "Should alway be true")
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testShouldReplaceText_attachment_multipleRemove() {
        let attachmentsToRemoveCount = 10
        shouldReplaceText_attachment(remove: attachmentsToRemoveCount)
    }
    func shouldReplaceText_attachment (remove: Int) {
        var textBuilder = NSAttributedString(string: "Test text")
        let range = NSRange(location: 0, length: 0)
        var initialAttachments = [Attachment]()

        for i in 0..<remove {
            let testAttachment = createTestAttachment(fileName: String(i), addImage: true)
            textBuilder = insertTextattachment(for: testAttachment, in: range, of: textBuilder)
            initialAttachments.append(testAttachment)
        }

        let attachmentToRemoveRange = NSRange(location: 0, length: textBuilder.length)
        let expectedAttachmentsLeft = [Attachment]()

        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: initialAttachments,
                                expectInsertCalled: nil,
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled(mustBeCalled: false),
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: true),
                                inlined: expectedAttachmentsLeft,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        let shouldReplace = vm.shouldReplaceText(in: attachmentToRemoveRange,
                                                 of: textBuilder,
                                                 with: "")
        XCTAssertTrue(shouldReplace, "Should alway be true")
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: handleUserClickedSelectMedia

    func testHandleUserClickedSelectMedia() {
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: true),
                                expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled(mustBeCalled: false),
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: false),
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
       vm.handleUserClickedSelectMedia()
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: handleUserClickedSelectDocument

    func testHandleUserClickedSelectDocument() {
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled(mustBeCalled: false),
                                expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled(mustBeCalled: true),
                                expInlinedAttachmentsCalled: expInlinedAttachmentChanged(mustBeCalled: false),
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        vm.handleUserClickedSelectDocument()
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: handleCursorPositionChange

    func testHandleCursorPositionChange_cursorBehindInlinedAttachment() {
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: nil,
                                expUserWantsToAddDocumentCalled: nil,
                                expInlinedAttachmentsCalled: nil,
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        let testPosition = 1
        vm.handleCursorPositionChange(newPosition: testPosition)
        vm.handleUserClickedSelectMedia()
        let inlinedImage = 1
        let expectedPosition = testPosition + inlinedImage
        XCTAssertEqual(vm.cursorPosition, expectedPosition,
                       "cursor should be placed behind inlined image")
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testHandleCursorPositionChange_noChangeAddingAttachment() {
        setupAssertionDelegates(initialPlaintext: nil,
                                initialAttributedText: nil,
                                initialInlinedAttachments: nil,
                                expectInsertCalled: expInsertTextCalled(mustBeCalled: false),
                                inserted: nil,
                                expUserWantsToAddMediaCalled: nil,
                                expUserWantsToAddDocumentCalled: nil,
                                expInlinedAttachmentsCalled: nil,
                                inlined: nil,
                                expBodyChangedCalled: expBodyChangedCalled(mustBeCalled: false),
                                exectedPlain: nil,
                                exectedHtml: nil)
        let testPosition = 1
        vm.handleCursorPositionChange(newPosition: testPosition)
        vm.handleUserClickedSelectDocument()
        let expectedPosition = testPosition
        XCTAssertEqual(vm.cursorPosition, expectedPosition,
                       "cursor position does not change attaching an non-ilined image")
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    // MARK: - Helpers

    private func setupAssertionDelegates(
        initialPlaintext: String? = nil, initialAttributedText: NSAttributedString? = nil, initialInlinedAttachments: [Attachment]? = nil,
        expectInsertCalled: XCTestExpectation? = nil, inserted: NSAttributedString? = nil,

        expUserWantsToAddMediaCalled: XCTestExpectation? = nil,
        expUserWantsToAddDocumentCalled: XCTestExpectation? = nil,
        expInlinedAttachmentsCalled: XCTestExpectation? = nil, inlined: [Attachment]? = nil,
        expBodyChangedCalled: XCTestExpectation? = nil, exectedPlain: String? = nil, exectedHtml: String? = nil) {
        // Delegate
        testDelegate = TestDelegate(expectInsertCalled: expectInsertCalled, inserted: inserted)

        // Result Delegate
        let newTestResultDelegate =
            TestResultDelegate(
                expUserWantsToAddMediaCalled: expUserWantsToAddMediaCalled, expUserWantsToAddDocumentCalled: expUserWantsToAddDocumentCalled,
                expInlinedAttachmentsCalled: expInlinedAttachmentsCalled, inlined: inlined,
                expBodyChangedCalled: expBodyChangedCalled, exectedPlain: exectedPlain, exectedHtml: exectedHtml)
        testResultDelegate = newTestResultDelegate
        vm = BodyCellViewModel(resultDelegate: newTestResultDelegate,
                               initialPlaintext: initialPlaintext,
                               initialAttributedText: initialAttributedText,
                               inlinedAttachments: initialInlinedAttachments,
                               account: nil)
        vm.delegate = testDelegate
        let aNonNullValue: CGFloat = 300.0
        vm.maxTextattachmentWidth = aNonNullValue
    }

    private func createTestAttachment(data: Data? = nil,
                                mimeType: String = "test/mimeType",
                                fileName: String? = nil,
                                size: Int? = nil,
                                url: URL? = nil,
                                addImage: Bool = false,
                                assetUrl: URL? = nil,
                                contentDisposition: Attachment.ContentDispositionType = .inline) -> Attachment {
        guard let att = createTestAttachments(numAttachments: 1,
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

    private func createTestAttachments(numAttachments: Int = 1,
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
                let imageData = MiscUtil.loadData(bundleClass: BodyCellViewModelTest.self,
                                                  fileName: imageFileName),
                let image = UIImage(data: imageData) else {
                    XCTFail("No img")
                    return []
            }

            for i in 0..<numAttachments {
                attachments.append(Attachment(data: data,
                                              mimeType: mimeType,
                                              fileName: fileName == nil ? "\(i)" : fileName,
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

    private func insertTextattachment(for attachment: Attachment,
                                      in range: NSRange,
                                      of string: NSAttributedString) -> NSAttributedString {
        let attachmentString = textAttachmentString(for: attachment)
        return insert(text: attachmentString, in: range, of: string)
    }

    private func textAttachmentString(for attachment: Attachment) -> NSAttributedString {
        guard let image = attachment.image else {
            XCTFail("No image")
            return NSAttributedString()
        }
        attachment.contentDisposition = .inline
        let textAttachment = TextAttachment()
        textAttachment.image = image
        textAttachment.attachment = attachment
        let imageString = NSAttributedString(attachment: textAttachment)
        return imageString
    }

    private func insert(text insertText: NSAttributedString,
                        in range: NSRange,
                        of text: NSAttributedString) -> NSAttributedString {
        let attrText = NSMutableAttributedString(attributedString: text)
        attrText.replaceCharacters(in: range, with: insertText)
        return attrText
    }

    // MARK: BodyCellViewModelDelegate

    private class TestDelegate: BodyCellViewModelDelegate {
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

    private class TestResultDelegate: BodyCellViewModelResultDelegate {
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
        }

        func bodyCellViewModelUserWantsToAddDocument(_ vm: BodyCellViewModel) {
            guard let exp = expUserWantsToAddDocumentCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
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
        }

        func bodyCellViewModel(_ vm: BodyCellViewModel, bodyAttributedString: NSAttributedString) {
        }
    }
}
