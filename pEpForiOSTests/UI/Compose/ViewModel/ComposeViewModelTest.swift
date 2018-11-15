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
        func composeViewModelDidComposeNewMail() {
            fatalError()
        }

        func composeViewModelDidModifyMessage() {
            fatalError()
        }

        func composeViewModelDidDeleteMessage() {
            fatalError()
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
