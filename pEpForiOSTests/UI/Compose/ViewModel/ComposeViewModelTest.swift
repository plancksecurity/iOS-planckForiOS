//
//  ComposeViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 15.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel
import PlanckToolbox

class ComposeViewModelTest: AccountDrivenTestBase {
    private var testDelegate: TestDelegate?
    var vm: ComposeViewModel?
    var outbox: Folder? {
        return account.firstFolder(ofType: .outbox)
    }
    var drafts: Folder? {
        return account.firstFolder(ofType: .drafts)
    }
    var sent: Folder? {
        return account.firstFolder(ofType: .sent)
    }

    override func setUp() {
        super.setUp()
        vm = ComposeViewModel(composeMode: nil,
                              prefilledTo: nil,
                              originalMessage: nil)
        assureOutboxExists()
        assureDraftsExists()
        assureSentExists()
    }

    // MARK: - isAttachmentSection

    func testIsAttachmentSection() {
        let msgWithAttachment = draftMessage(attachmentsSet: true)
        assert(originalMessage: msgWithAttachment)
        guard
            let lastSection = vm?.sections.last,
            let numSections = vm?.sections.count else {
                XCTFail()
                return
        }
        let numRows = lastSection.rows.count
        let idxPath = IndexPath(row: numRows - 1, section: numSections - 1)
        XCTAssertTrue(vm?.isAttachmentSection(indexPath: idxPath) ?? false,
                      "Last row in last section must be attachment")
    }

    // MARK: - Helper

    private func assureOutboxExists() {
        if outbox == nil {
            let createe = Folder(name: "outbox", parent: nil, account: account, folderType: .outbox)
            createe.session.commit()
        }
        XCTAssertNotNil(outbox)
    }

    private func assureDraftsExists() {
        if drafts == nil {
            let createe = Folder(name: "drafts",
                                 parent: nil,
                                 account: account,
                                 folderType: .drafts)
            createe.session.commit()
        }
        XCTAssertNotNil(drafts)
    }

    private func assureSentExists() {
        if sent == nil {
            let createe = Folder(name: "sent",
                                 parent: nil,
                                 account: account,
                                 folderType: .sent)
            createe.session.commit()
        }
        XCTAssertNotNil(sent)
    }

    private func draftMessage(bccSet: Bool = false, attachmentsSet: Bool = false) -> Message {
        return message(inFolderOfType: .drafts, bccSet: bccSet, attachmentsSet: attachmentsSet)
    }

    private func message(inFolderOfType parentType: FolderType = .inbox,
                         bccSet: Bool = false,
                         attachmentsSet: Bool = false) -> Message {
        let folder = Folder(name: "\(parentType)",
            parent: parentType == .inbox ? nil : account.firstFolder(ofType: .inbox),
            account: account,
            folderType: parentType)
        folder.session.commit()
        let createe = Message(uuid: UUID().uuidString, parentFolder: folder)
        if bccSet {
            createe.replaceBcc(with: [account.user])
        }
        if attachmentsSet {
            let att = attachment()
            createe.replaceAttachments(with: [att])
        }
        createe.session.commit()
        return createe
    }

    private func attachment(
        ofType type: Attachment.ContentDispositionType = .attachment ) -> Attachment {
        let imageFileName = "PorpoiseGalaxy_HubbleFraile_960.jpg"
        guard
            let imageData = MiscUtil.loadData(bundleClass: ComposeViewModelTest.self,
                                              fileName: imageFileName),
            let image = UIImage(data: imageData) else {
            XCTFail()
            return Attachment(data: nil, mimeType: "meh", contentDisposition: .attachment)
        }
        let createe: Attachment
        if type == .inline {
            createe = Attachment(data: image.jpegData(compressionQuality: 1.0), mimeType: "image/jpg", contentDisposition: type)
            createe.image = image
        } else {
            createe = Attachment(data: imageData,
                                 mimeType: "video/quicktime",
                                 contentDisposition: type)
        }
        createe.fileName = UUID().uuidString
        return createe
    }

    private func assert(composeMode: ComposeUtil.ComposeMode? = nil,
                        prefilledTo: Identity? = nil,
                        originalMessage: Message? = nil,
                        contentChangedMustBeCalled: Bool? = nil,/*TestDelegate realted params*/
                        expectedContentChangedIndexPath: IndexPath? = nil,
                        focusSwitchedMustBeCalled: Bool? = nil,
                        validatedStateChangedMustBeCalled: Bool? = nil,
                        expectedIsValidated: Bool? = nil,
                        modelChangedMustBeCalled: Bool? = nil,
                        sectionChangedMustBeCalled: Bool? = nil,
                        expectedSection: Int? = nil,
                        colorBatchNeedsUpdateMustBeCalled: Bool? = nil,
                        expectedRating: Rating? = nil,
                        expectedProtectionEnabled: Bool? = nil,
                        hideSuggestionsMustBeCalled: Bool? = nil,
                        showSuggestionsMustBeCalled: Bool? = nil,
                        showContactsMustBeCalled: Bool? = nil,
                        expectedShowSuggestionsIndexPath: IndexPath? = nil,
                        suggestionsScrollFocusChangedMustBeCalled: Bool? = nil,
                        expectedNewSuggestionsScrollFocusIsVisible: Bool? = nil,
                        showMediaAttachmentPickerMustBeCalled: Bool? = nil,
                        hideMediaAttachmentPickerMustBeCalled: Bool? = nil,
                        showDocumentAttachmentPickerMustBeCalled: Bool? = nil,
                        documentAttachmentPickerDonePickerCalled: Bool? = nil,
                        showActionSheetCalled: Bool? = nil,
                        didComposeNewMailMustBeCalled: Bool? = nil,/*TestResultDelegate realted params*/
                        didModifyMessageMustBeCalled: Bool? = nil,
                        didDeleteMessageMustBeCalled: Bool? = nil) {
        // TestDelegate
        var expContentChangedCalled: XCTestExpectation? = nil
        if let exp = contentChangedMustBeCalled {
            expContentChangedCalled =
                expectation(description: "expContentChangedCalled")
            expContentChangedCalled?.isInverted = !exp
        }

        var expFocusSwitchedCalled: XCTestExpectation? = nil
        if let exp = focusSwitchedMustBeCalled {
            expFocusSwitchedCalled =
                expectation(description: "expFocusSwitchedCalled")
            expFocusSwitchedCalled?.isInverted = !exp
        }

        var expValidatedStateChangedCalled: XCTestExpectation? = nil
        if let exp = validatedStateChangedMustBeCalled {
            expValidatedStateChangedCalled =
                expectation(description: "expValidatedStateChangedCalled")
            expValidatedStateChangedCalled?.isInverted = !exp
        }

        var expModelChangedCalled: XCTestExpectation? = nil
        if let exp = modelChangedMustBeCalled {
            expModelChangedCalled =
                expectation(description: "expModelChangedCalled")
            expModelChangedCalled?.isInverted = !exp
        }

        var expSectionChangedCalled: XCTestExpectation? = nil
        if let exp = sectionChangedMustBeCalled {
            expSectionChangedCalled =
                expectation(description: "expSectionChangedCalled")
            expSectionChangedCalled?.isInverted = !exp
            // Overfulfill is espected. When unwrapping CcBcc fields, wrapper section AND
            // recipinets section changes.
            expSectionChangedCalled?.assertForOverFulfill = false
        }

        var expColorBatchNeedsUpdateCalled: XCTestExpectation? = nil
        if let exp = colorBatchNeedsUpdateMustBeCalled {
            expColorBatchNeedsUpdateCalled =
                expectation(description: "expColorBatchNeedsUpdateCalled")
            expColorBatchNeedsUpdateCalled?.isInverted = !exp
        }

        var expHideSuggestionsCalled: XCTestExpectation? = nil
        if let exp = hideSuggestionsMustBeCalled {
            expHideSuggestionsCalled =
                expectation(description: "expHideSuggestionsCalled")
            expHideSuggestionsCalled?.isInverted = !exp
        }

        var expSuggestionsScrollFocusChangedCalled: XCTestExpectation? = nil
        if let exp = suggestionsScrollFocusChangedMustBeCalled {
            expSuggestionsScrollFocusChangedCalled =
                expectation(description: "expSuggestionsScrollFocusChangedCalled")
            expSuggestionsScrollFocusChangedCalled?.isInverted = !exp
        }

        var expShowSuggestionsCalled: XCTestExpectation? = nil
        if let exp = showSuggestionsMustBeCalled {
            expShowSuggestionsCalled =
                expectation(description: "expShowSuggestionsCalled")
            expShowSuggestionsCalled?.isInverted = !exp
        }

        var expShowContactsCalled: XCTestExpectation? = nil
        if let exp = showContactsMustBeCalled {
            expShowContactsCalled = expectation(description: "expShowContactsCalled")
            expShowContactsCalled?.isInverted = !exp
        }

        var expShowMediaAttachmentPickerCalled: XCTestExpectation? = nil
        if let exp = showMediaAttachmentPickerMustBeCalled {
            expShowMediaAttachmentPickerCalled =
                expectation(description: "expShowMediaAttachmentPickerCalled")
            expShowMediaAttachmentPickerCalled?.isInverted = !exp
        }

        var expHideMediaAttachmentPickerCalled: XCTestExpectation? = nil
        if let exp = hideMediaAttachmentPickerMustBeCalled {
            expHideMediaAttachmentPickerCalled =
                expectation(description: "expHideMediaAttachmentPickerCalled")
            expHideMediaAttachmentPickerCalled?.isInverted = !exp
        }

        var expShowDocumentAttachmentPickerCalled: XCTestExpectation? = nil
        if let exp = showDocumentAttachmentPickerMustBeCalled {
            expShowDocumentAttachmentPickerCalled =
                expectation(description: "expShowDocumentAttachmentPickerCalled")
            expShowDocumentAttachmentPickerCalled?.isInverted = !exp
        }

        var expDocumentAttachmentPickerDonePickerCalled: XCTestExpectation? = nil
        if let exp = documentAttachmentPickerDonePickerCalled {
            expDocumentAttachmentPickerDonePickerCalled =
                expectation(description: "expDocumentAttachmentPickerDonePickerCalled")
            expDocumentAttachmentPickerDonePickerCalled?.isInverted = !exp
        }

        var expShowActionSheetCalled: XCTestExpectation? = nil
        if let exp = showActionSheetCalled {
            expShowActionSheetCalled =
                expectation(description: "expShowActionSheetCalled")
            expShowActionSheetCalled?.isInverted = !exp
        }

        testDelegate =
            TestDelegate(expContentChangedCalled: expContentChangedCalled,
                         expectedContentChangedIndexPath: expectedContentChangedIndexPath,
                         expFocusSwitchedCalled: expFocusSwitchedCalled,
                         expValidatedStateChangedCalled: expValidatedStateChangedCalled,
                         expectedIsValidated: expectedIsValidated,
                         expModelChangedCalled: expModelChangedCalled,
                         expSectionChangedCalled: expSectionChangedCalled,
                         expectedSection: expectedSection,
                         expColorBatchNeedsUpdateCalled: nil,
                         expectedRating: expectedRating,
                         expectedProtectionEnabled: expectedProtectionEnabled,
                         expHideSuggestionsCalled: expHideSuggestionsCalled,
                         expShowSuggestionsCalled: expShowSuggestionsCalled,
                         expShowContactsPickerCalled: expShowContactsCalled,
                         expSuggestionsScrollFocusChangedCalled: expSuggestionsScrollFocusChangedCalled,
                         expectedScrollFocus: expectedNewSuggestionsScrollFocusIsVisible,
                         expectedShowSuggestionsIndexPath: expectedShowSuggestionsIndexPath,
                         expShowMediaAttachmentPickerCalled: expShowMediaAttachmentPickerCalled,
                         expHideMediaAttachmentPickerCalled: expHideMediaAttachmentPickerCalled,
                         expShowDocumentAttachmentPickerCalled: expShowDocumentAttachmentPickerCalled,
                         expDocumentAttachmentPickerDonePickerCalled: expDocumentAttachmentPickerDonePickerCalled,
                         expShowActionSheetCalled: expShowActionSheetCalled)

        vm = ComposeViewModel(composeMode: composeMode,
                              prefilledTo: prefilledTo,
                              originalMessage: originalMessage)
        vm?.delegate = testDelegate
        // Set _after_ the delegate is set because at this point we are not interested in callbacks
        // triggered by setting the delegate.
        testDelegate?.expColorBatchNeedsUpdateCalled = expColorBatchNeedsUpdateCalled
    }

    private class TestDelegate: ComposeViewModelDelegate {


        func showTwoButtonAlert(withTitle title: String, message: String, cancelButtonText: String, positiveButtonText: String, cancelButtonAction: @escaping () -> Void, positiveButtonAction: @escaping () -> Void) {
        }

        func dismiss() {
        }

        let expContentChangedCalled: XCTestExpectation?
        let expectedContentChangedIndexPath: IndexPath?

        let expFocusSwitchedCalled: XCTestExpectation?

        let expValidatedStateChangedCalled: XCTestExpectation?
        let expectedIsValidated: Bool?

        let expModelChangedCalled: XCTestExpectation?

        let expSectionChangedCalled: XCTestExpectation?
        let expectedSection: Int?

        var expColorBatchNeedsUpdateCalled: XCTestExpectation?
        let expectedRating: Rating?
        let expectedProtectionEnabled: Bool?

        let expHideSuggestionsCalled: XCTestExpectation?

        let expShowSuggestionsCalled: XCTestExpectation?
        let expShowContactsPickerCalled: XCTestExpectation?
        let expectedShowSuggestionsIndexPath: IndexPath?

        let expSuggestionsScrollFocusChangedCalled: XCTestExpectation?
        let expectedScrollFocus: Bool?

        let expShowMediaAttachmentPickerCalled: XCTestExpectation?

        let expHideMediaAttachmentPickerCalled: XCTestExpectation?

        let expShowDocumentAttachmentPickerCalled: XCTestExpectation?

        let expDocumentAttachmentPickerDonePickerCalled: XCTestExpectation?

        let expShowActionSheetCalled: XCTestExpectation?

        init(expContentChangedCalled: XCTestExpectation?,
             expectedContentChangedIndexPath: IndexPath?,
             expFocusSwitchedCalled: XCTestExpectation?,
             expValidatedStateChangedCalled: XCTestExpectation?,
             expectedIsValidated: Bool?,
             expModelChangedCalled: XCTestExpectation?,
             expSectionChangedCalled: XCTestExpectation?,
             expectedSection: Int?,
             expColorBatchNeedsUpdateCalled: XCTestExpectation?,
             expectedRating: Rating?,
             expectedProtectionEnabled: Bool?,
             expHideSuggestionsCalled: XCTestExpectation?,
             expShowSuggestionsCalled: XCTestExpectation?,
             expShowContactsPickerCalled: XCTestExpectation?,
             expSuggestionsScrollFocusChangedCalled: XCTestExpectation?,
             expectedScrollFocus: Bool?,
             expectedShowSuggestionsIndexPath: IndexPath?,
             expShowMediaAttachmentPickerCalled: XCTestExpectation?,
             expHideMediaAttachmentPickerCalled: XCTestExpectation?,
             expShowDocumentAttachmentPickerCalled: XCTestExpectation?,
             expDocumentAttachmentPickerDonePickerCalled: XCTestExpectation?,
             expShowActionSheetCalled: XCTestExpectation?) {
            self.expContentChangedCalled = expContentChangedCalled
            self.expectedContentChangedIndexPath = expectedContentChangedIndexPath
            self.expFocusSwitchedCalled = expFocusSwitchedCalled
            self.expValidatedStateChangedCalled = expValidatedStateChangedCalled
            self.expectedIsValidated = expectedIsValidated
            self.expModelChangedCalled = expModelChangedCalled
            self.expSectionChangedCalled = expSectionChangedCalled
            self.expectedSection = expectedSection
            self.expColorBatchNeedsUpdateCalled =  expColorBatchNeedsUpdateCalled
            self.expectedRating = expectedRating
            self.expectedProtectionEnabled = expectedProtectionEnabled
            self.expHideSuggestionsCalled = expHideSuggestionsCalled
            self.expShowSuggestionsCalled = expShowSuggestionsCalled
            self.expShowContactsPickerCalled = expShowContactsPickerCalled
            self.expSuggestionsScrollFocusChangedCalled = expSuggestionsScrollFocusChangedCalled
            self.expectedScrollFocus = expectedScrollFocus
            self.expectedShowSuggestionsIndexPath = expectedShowSuggestionsIndexPath
            self.expShowMediaAttachmentPickerCalled = expShowMediaAttachmentPickerCalled
            self.expHideMediaAttachmentPickerCalled = expHideMediaAttachmentPickerCalled
            self.expShowDocumentAttachmentPickerCalled = expShowDocumentAttachmentPickerCalled
            self.expDocumentAttachmentPickerDonePickerCalled = expDocumentAttachmentPickerDonePickerCalled
            self.expShowActionSheetCalled = expShowActionSheetCalled
        }

        func contentChanged(inRowAt indexPath: IndexPath) {
            guard let exp = expContentChangedCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedContentChangedIndexPath {
                XCTAssertEqual(indexPath, expected)
            }
        }

        func focusSwitched() {
            guard let exp = expFocusSwitchedCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func validatedStateChanged(to isValidated: Bool) {
            guard let exp = expValidatedStateChangedCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedIsValidated {
                XCTAssertEqual(isValidated, expected)
            }
        }

        func modelChanged() {
            guard let exp = expModelChangedCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func sectionChanged(section: Int) {
            guard let exp = expSectionChangedCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedSection {
                XCTAssertEqual(section, expected)
            }
        }

        func colorBatchNeedsUpdate(for rating: Rating, protectionEnabled: Bool, hasRecipients: Bool) {
            guard let exp = expColorBatchNeedsUpdateCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedRating {
                XCTAssertEqual(rating, expected)
            }
            if let expectedProtection = expectedProtectionEnabled {
                XCTAssertEqual(protectionEnabled, expectedProtection)
            }
        }

        func hideSuggestions() {
            guard let exp = expHideSuggestionsCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func showSuggestions(forRowAt indexPath: IndexPath) {
            guard let exp = expShowSuggestionsCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedShowSuggestionsIndexPath {
                XCTAssertEqual(indexPath, expected)
            }
        }

        func showContactsPicker() {
            guard let exp = expShowContactsPickerCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func suggestions(haveScrollFocus: Bool) {
            guard let exp = expSuggestionsScrollFocusChangedCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedScrollFocus {
                XCTAssertEqual(haveScrollFocus, expected)
            }
        }

        func showMediaAttachmentPicker() {
            guard let exp = expShowMediaAttachmentPickerCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func hideMediaAttachmentPicker() {
            guard let exp = expHideMediaAttachmentPickerCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func showDocumentAttachmentPicker() {
            guard let exp = expShowDocumentAttachmentPickerCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func documentAttachmentPickerDone() {
            guard let exp = expDocumentAttachmentPickerDonePickerCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func showActionSheetWith(title: String, smallTitle: String, mediumTitle: String, largeTitle: String, actualTitle: String,
                                 callback: @escaping (JPEGQuality) -> ()?) {
            guard let exp = expShowActionSheetCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func isPresentingContactsPicker() -> Bool {
            return false
        }

        func isDismissing() -> Bool {
            return false
        }
        func showRecipientsBanner() { }

        func hideRecipientsBanner() { }

        func removeRecipientsFromTextfields(addresses: [String]) { }

    }
}
