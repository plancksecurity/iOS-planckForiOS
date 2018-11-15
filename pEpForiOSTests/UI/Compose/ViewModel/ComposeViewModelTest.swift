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
