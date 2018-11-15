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
        func contentChanged(inRowAt indexPath: IndexPath) {
            fatalError()
        }

        func focusSwitched() {
            fatalError()
        }

        func validatedStateChanged(to isValidated: Bool) {
            fatalError()
        }

        func modelChanged() {
            fatalError()
        }

        func sectionChanged(section: Int) {
            fatalError()
        }

        func colorBatchNeedsUpdate(for rating: PEP_rating, protectionEnabled: Bool) {
            fatalError()
        }

        func hideSuggestions() {
            fatalError()
        }

        func showSuggestions(forRowAt indexPath: IndexPath) {
            fatalError()
        }

        func showMediaAttachmentPicker() {
            fatalError()
        }

        func hideMediaAttachmentPicker() {
            fatalError()
        }

        func showDocumentAttachmentPicker() {
            fatalError()
        }

        func documentAttachmentPickerDone() {
            fatalError()
        }
    }

}
