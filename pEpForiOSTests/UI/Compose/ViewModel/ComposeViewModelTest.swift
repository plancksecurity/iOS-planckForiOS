//
//  ComposeViewModelTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 15.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class ComposeViewModelTest: XCTestCase {
    private var testDelegate: TestDelegate?
    private var testResultDelegate: TestResultDelegate?
    var testee: ComposeViewModel?

    // MARK: - Helper

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
                        expectedRating: PEP_rating? = nil,
                        expectedProtectionEnabled: Bool? = nil,
                        hideSuggestionsMustBeCalled: Bool? = nil,
                        showSuggestionsMustBeCalled: Bool? = nil,
                        expectedShowSuggestionsIndexPath: IndexPath? = nil,
                        showMediaAttachmentPickerMustBeCalled: Bool? = nil,
                        hideMediaAttachmentPickerMustBeCalled: Bool? = nil,
                        showDocumentAttachmentPickerMustBeCalled: Bool? = nil,
                        documentAttachmentPickerDonePickerCalled: Bool? = nil,
                        didComposeNewMailMustBeCalled: Bool? = nil,/*TestResultDelegate realted params*/
                        didModifyMessageMustBeCalled: Bool? = nil,
                        didDeleteMessageMustBeCalled: Bool?) {
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

        var expShowSuggestionsCalled: XCTestExpectation? = nil
        if let exp = showSuggestionsMustBeCalled {
            expShowSuggestionsCalled =
                expectation(description: "expShowSuggestionsCalled")
            expShowSuggestionsCalled?.isInverted = !exp
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

        testDelegate =
            TestDelegate(expContentChangedCalled: expContentChangedCalled,
                         expectedContentChangedIndexPath: expectedContentChangedIndexPath,
                         expFocusSwitchedCalled: expFocusSwitchedCalled,
                         expValidatedStateChangedCalled: expValidatedStateChangedCalled,
                         expectedIsValidated: expectedIsValidated,
                         expModelChangedCalled: expModelChangedCalled,
                         expSectionChangedCalled: expSectionChangedCalled,
                         expectedSection: expectedSection,
                         expColorBatchNeedsUpdateCalled: expColorBatchNeedsUpdateCalled,
                         expectedRating: expectedRating,
                         expectedProtectionEnabled: expectedProtectionEnabled,
                         expHideSuggestionsCalled: expHideSuggestionsCalled,
                         expShowSuggestionsCalled: expShowSuggestionsCalled,
                         expectedShowSuggestionsIndexPath: expectedShowSuggestionsIndexPath,
                         expShowMediaAttachmentPickerCalled: expShowMediaAttachmentPickerCalled,
                         expHideMediaAttachmentPickerCalled: expHideMediaAttachmentPickerCalled,
                         expShowDocumentAttachmentPickerCalled: expShowDocumentAttachmentPickerCalled,
                         expDocumentAttachmentPickerDonePickerCalled:
                expDocumentAttachmentPickerDonePickerCalled)

        // TestResultDelegate

        var expDidComposeNewMailCalled: XCTestExpectation? = nil
        if let exp = didComposeNewMailMustBeCalled {
            expDidComposeNewMailCalled =
                expectation(description: "expDidComposeNewMailCalled")
            expDidComposeNewMailCalled?.isInverted = !exp
        }

        var expDidModifyMessageCalled: XCTestExpectation? = nil
        if let exp = didModifyMessageMustBeCalled {
            expDidModifyMessageCalled =
                expectation(description: "expDidModifyMessageCalled")
            expDidModifyMessageCalled?.isInverted = !exp
        }

        var expDidDeleteMessageCalled: XCTestExpectation? = nil
        if let exp = didDeleteMessageMustBeCalled {
            expDidDeleteMessageCalled =
                expectation(description: "expDidDeleteMessageCalled")
            expDidDeleteMessageCalled?.isInverted = !exp
        }

        testResultDelegate =
            TestResultDelegate(expDidComposeNewMailCalled: expDidComposeNewMailCalled,
                               expDidModifyMessageCalled: expDidModifyMessageCalled,
                               expDidDeleteMessageCalled: expDidDeleteMessageCalled)    
        testee = ComposeViewModel(resultDelegate: testResultDelegate,
                                  composeMode: composeMode,
                                  prefilledTo: prefilledTo,
                                  originalMessage: originalMessage)
    }

    private class TestResultDelegate: ComposeViewModelResultDelegate {
        let expDidComposeNewMailCalled: XCTestExpectation?
        let expDidModifyMessageCalled: XCTestExpectation?
        let expDidDeleteMessageCalled: XCTestExpectation?

        init(expDidComposeNewMailCalled: XCTestExpectation?,
             expDidModifyMessageCalled: XCTestExpectation?,
             expDidDeleteMessageCalled: XCTestExpectation?) {
            self.expDidComposeNewMailCalled = expDidComposeNewMailCalled
            self.expDidModifyMessageCalled = expDidModifyMessageCalled
            self.expDidDeleteMessageCalled = expDidDeleteMessageCalled

        }

        func composeViewModelDidComposeNewMail() {
            guard let exp = expDidComposeNewMailCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func composeViewModelDidModifyMessage() {
            guard let exp = expDidModifyMessageCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }

        func composeViewModelDidDeleteMessage() {
            guard let exp = expDidDeleteMessageCalled else {
                // We ignore called or not
                return
            }
            exp.fulfill()
        }
    }

    private class TestDelegate:  ComposeViewModelDelegate {
        let expContentChangedCalled: XCTestExpectation?
        let expectedContentChangedIndexPath: IndexPath?

        let expFocusSwitchedCalled: XCTestExpectation?

        let expValidatedStateChangedCalled: XCTestExpectation?
        let expectedIsValidated: Bool?

        let expModelChangedCalled: XCTestExpectation?

        let expSectionChangedCalled: XCTestExpectation?
        let expectedSection: Int?

        let expColorBatchNeedsUpdateCalled: XCTestExpectation?
        let expectedRating: PEP_rating?
        let expectedProtectionEnabled: Bool?

        let expHideSuggestionsCalled: XCTestExpectation?

        let expShowSuggestionsCalled: XCTestExpectation?
        let expectedShowSuggestionsIndexPath: IndexPath?

        let expShowMediaAttachmentPickerCalled: XCTestExpectation?

        let expHideMediaAttachmentPickerCalled: XCTestExpectation?

        let expShowDocumentAttachmentPickerCalled: XCTestExpectation?

        let expDocumentAttachmentPickerDonePickerCalled: XCTestExpectation?

        init(expContentChangedCalled: XCTestExpectation?,
             expectedContentChangedIndexPath: IndexPath?,
             expFocusSwitchedCalled: XCTestExpectation?,
             expValidatedStateChangedCalled: XCTestExpectation?,
             expectedIsValidated: Bool?,
             expModelChangedCalled: XCTestExpectation?,
             expSectionChangedCalled: XCTestExpectation?,
             expectedSection: Int?,
             expColorBatchNeedsUpdateCalled: XCTestExpectation?,
             expectedRating: PEP_rating?,
             expectedProtectionEnabled: Bool?,
             expHideSuggestionsCalled: XCTestExpectation?,
             expShowSuggestionsCalled: XCTestExpectation?,
             expectedShowSuggestionsIndexPath: IndexPath?,
             expShowMediaAttachmentPickerCalled: XCTestExpectation?,
             expHideMediaAttachmentPickerCalled: XCTestExpectation?,
             expShowDocumentAttachmentPickerCalled: XCTestExpectation?,
             expDocumentAttachmentPickerDonePickerCalled: XCTestExpectation?) {
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
            self.expectedShowSuggestionsIndexPath = expectedShowSuggestionsIndexPath
            self.expShowMediaAttachmentPickerCalled = expShowMediaAttachmentPickerCalled
            self.expHideMediaAttachmentPickerCalled = expHideMediaAttachmentPickerCalled
            self.expShowDocumentAttachmentPickerCalled = expShowDocumentAttachmentPickerCalled
            self.expDocumentAttachmentPickerDonePickerCalled =
            expDocumentAttachmentPickerDonePickerCalled
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

        func colorBatchNeedsUpdate(for rating: PEP_rating, protectionEnabled: Bool) {
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
    }
}
