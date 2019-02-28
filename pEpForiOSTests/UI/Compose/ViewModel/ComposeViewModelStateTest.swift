//
//  ComposeViewModelStateTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 14.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel

class ComposeViewModelStateTest: CoreDataDrivenTestBase {
    /// Async PEPSession calls that take quite some time
    let asyncPEPSessionCallWaitTime = 2.0
    private var testDelegate: TestDelegate?
    var testee: ComposeViewModel.ComposeViewModelState?
    var draftedMessageAllButBccSet: Message?
    let someone = Identity(address: "someone@someone.someone")

    override func setUp() {
        super.setUp()
        let drafts = Folder(name: "Inbox", parent: nil, account: account, folderType: .drafts)
        drafts.save()
        let msg = Message(uuid: UUID().uuidString, parentFolder: drafts)
        msg.from = account.user
        msg.to = [account.user, someone]
        msg.cc = [someone]
        msg.shortMessage = "shortMessage"
        msg.longMessage = "longMessage"
        msg.longMessageFormatted = "longMessageFormatted"
        msg.attachments = [Attachment(data: Data(),
                                      mimeType: "image/jpg",
                                      contentDisposition: .attachment)]
        msg.attachments.append(Attachment(data: Data(),
                                          mimeType: "image/jpg",
                                          contentDisposition: .inline))
        msg.save()
        draftedMessageAllButBccSet = msg

        setupSimpleTestee()
    }

    // MARK: - initData

    func testInitData() {
        let initData = ComposeViewModel.InitData()
        testee = ComposeViewModel.ComposeViewModelState(initData: initData, delegate: nil)
        guard let testeeInitData = testee?.initData else {
            XCTFail("No testee")
            return
        }
        XCTAssertNotNil(testeeInitData)
    }

    // MARK: - delegate

    func testInitialDelegateIsSet() {
        let initData = ComposeViewModel.InitData()
        let delegate = TestDelegate()
        testee = ComposeViewModel.ComposeViewModelState(initData: initData, delegate: delegate)
        XCTAssertNotNil(testee?.delegate)
    }

    // MARK: - bccWrapped

    func testBccWrapped_initial() {
        guard let wrapped = testee?.bccWrapped else {
            XCTFail()
            return
        }
        XCTAssertTrue(wrapped)
    }

    func testBccWrapped_unwrapped() {
        testee?.setBccUnwrapped()
        guard let wrapped = testee?.bccWrapped else {
            XCTFail()
            return
        }
        XCTAssertFalse(wrapped)
    }

    // MARK: - Validation ( recipient changes )

    func testValidate() {
        let expectedStateIsValid = false
        assert(ignoreDelegateCallsWhileInitializing: false,
               didChangeValidationStateMustBeCalled: true,
               expectedStateIsValid: expectedStateIsValid,
               didChangePEPRatingMustBeCalled: false,
               expectedNewRating: nil,
               didChangeProtectionMustBeCalled: false,
               expectedNewProtection: nil)
        waitForExpectations(timeout: UnitTestUtils.waitTime)
    }

    func testValidate_changeTos_noRecipients() {
        let recipients = [Identity]()
        assertValidatation(expectedStateIsValid: false,
                           expectedNewRating: nil)
        testee?.toRecipients = recipients
        waitForExpectations(timeout: asyncPEPSessionCallWaitTime)
    }

    func testValidate_changeTos_grey() {
        let recipients = [someone, account.user]
        assertValidatation(expectedStateIsValid: true,
                           expectedNewRating: PEPRatingUnencrypted)
        testee?.toRecipients = recipients
        waitForExpectations(timeout: asyncPEPSessionCallWaitTime)
    }

    func testValidate_changeTos_green() {
        let recipients = [account.user]
        assertValidatation(expectedStateIsValid: true,
                           expectedNewRating: PEP_rating_trusted_and_anonymized)
        testee?.toRecipients = recipients
        waitForExpectations(timeout: asyncPEPSessionCallWaitTime)
    }

    func testValidate_changeCcs_grey() {
        let recipients = [someone, account.user]
        assertValidatation(expectedStateIsValid: true,
                           expectedNewRating: PEPRatingUnencrypted)
        testee?.ccRecipients = recipients
        waitForExpectations(timeout: asyncPEPSessionCallWaitTime)
    }

    func testValidate_changeCCs_green() {
        let recipients = [account.user]
        assertValidatation(expectedStateIsValid: true,
                           expectedNewRating: PEP_rating_trusted_and_anonymized)
        testee?.ccRecipients = recipients
        waitForExpectations(timeout: asyncPEPSessionCallWaitTime)
    }

    // MARK: - edited

    func testEdited_noChange() {
        guard let edited = testee?.edited else {
            XCTFail()
            return
        }
        XCTAssertFalse(edited)
    }

    func testEdited_dirty_changedTos() {
        testee?.toRecipients = [someone]
        guard let edited = testee?.edited else {
            XCTFail()
            return
        }
        XCTAssertTrue(edited)
    }

    func testEdited_dirty_changedCcs() {
        testee?.ccRecipients = [someone]
        guard let edited = testee?.edited else {
            XCTFail()
            return
        }
        XCTAssertTrue(edited)
    }

    func testEdited_dirty_changedBccs() {
        testee?.bccRecipients = [someone]
        guard let edited = testee?.edited else {
            XCTFail()
            return
        }
        XCTAssertTrue(edited)
    }

    func testEdited_dirty_changedSubject() {
        testee?.subject = #function
        guard let edited = testee?.edited else {
            XCTFail()
            return
        }
        XCTAssertTrue(edited)
    }

    func testEdited_dirty_changedBodyPlaintext() {
        testee?.bodyPlaintext = #function
        guard let edited = testee?.edited else {
            XCTFail()
            return
        }
        XCTAssertTrue(edited)
    }

    func testEdited_dirty_changedBodyHtml() {
        testee?.bodyHtml = #function
        guard let edited = testee?.edited else {
            XCTFail()
            return
        }
        XCTAssertTrue(edited)
    }

    func testEdited_dirty_changedNonInlinedAttachments() {
        testee?.nonInlinedAttachments = [Attachment(data: nil,
                                                    mimeType: #function,
                                                    contentDisposition: .attachment)]
        guard let edited = testee?.edited else {
            XCTFail()
            return
        }
        XCTAssertTrue(edited)
    }

    // MARK: - userCanToggleProtection

    func testUserCanToggleProtection_grey() {
        guard let canToggleProtection = testee?.userCanToggleProtection() else {
            XCTFail()
            return
        }
        XCTAssertFalse(canToggleProtection)
    }

    func testUserCanToggleProtection_green() {
        // Setup green state ...
        let recipients = [account.user]
        assertValidatation(expectedStateIsValid: true,
                           expectedNewRating: PEP_rating_trusted_and_anonymized)
        testee?.toRecipients = recipients
        waitForExpectations(timeout: asyncPEPSessionCallWaitTime)
        // ... and assert can toggle works correctly
        guard let canToggleProtection = testee?.userCanToggleProtection() else {
            XCTFail()
            return
        }
        XCTAssertTrue(canToggleProtection)
    }

    // testUserCanToggleProtection: state yellow is untested. To expensive.

    func testUserCanToggleProtection_green_bccSet() {
        // Setup green state ...
        let recipients = [account.user]
        assertValidatation(expectedStateIsValid: true,
                           expectedNewRating: PEP_rating_trusted_and_anonymized)
        testee?.toRecipients = recipients
        waitForExpectations(timeout: asyncPEPSessionCallWaitTime)
        // ... set BCC ...
        testDelegate?.ignoreAll = true
        testee?.bccRecipients = recipients
        // ... and assert can toggle works correctly
        guard let canToggleProtection = testee?.userCanToggleProtection() else {
            XCTFail()
            return
        }
        XCTAssertFalse(canToggleProtection)
    }

    // MARK: - HELPER

    private func assertValidatation(didChangeValidationStateMustBeCalled: Bool = true,
                                    expectedStateIsValid: Bool,
                                    expectedNewRating: PEP_rating? = nil) {
        try! PEPSession().mySelf(account.user.pEpIdentity())
        assert(ignoreDelegateCallsWhileInitializing: true,
               didChangeValidationStateMustBeCalled: true,
               expectedStateIsValid: expectedStateIsValid,
               didChangePEPRatingMustBeCalled: expectedNewRating != nil,
               expectedNewRating: expectedNewRating,
               didChangeProtectionMustBeCalled: false)
    }

    private func assert(ignoreDelegateCallsWhileInitializing: Bool = true,
                        didChangeValidationStateMustBeCalled: Bool? = nil,
                        expectedStateIsValid: Bool? = nil,
                        didChangePEPRatingMustBeCalled: Bool? = nil,
                        expectedNewRating: PEP_rating? = nil,
                        didChangeProtectionMustBeCalled: Bool? = nil,
                        expectedNewProtection: Bool? = nil) {
        var expDidChangeValidationStateToCalled: XCTestExpectation? = nil
        if let exp = didChangeValidationStateMustBeCalled {
            expDidChangeValidationStateToCalled =
                expectation(description: "expDidChangeValidationStateToCalled")
            expDidChangeValidationStateToCalled?.isInverted = !exp
            expDidChangeValidationStateToCalled?.assertForOverFulfill = false
        }

        var expDidChangePEPRatingToCalled: XCTestExpectation? = nil
        if let exp = didChangePEPRatingMustBeCalled {
            expDidChangePEPRatingToCalled =
                expectation(description: "expDidChangePEPRatingToCalled")
            expDidChangePEPRatingToCalled?.isInverted = !exp
            expDidChangePEPRatingToCalled?.assertForOverFulfill = false
        }

        var expDidChangeProtectionCalled: XCTestExpectation? = nil
        if let exp = didChangeProtectionMustBeCalled {
            expDidChangeProtectionCalled =
                expectation(description: "expDidChangeProtectionCalled")
            expDidChangeProtectionCalled?.isInverted = !exp
            expDidChangeProtectionCalled?.assertForOverFulfill = false
        }

        testDelegate =
            TestDelegate(expDidChangeValidationStateToCalled: expDidChangeValidationStateToCalled,
                         expectedStateIsValid: expectedStateIsValid,
                         expDidChangePEPRatingToCalled: expDidChangePEPRatingToCalled,
                         expectedNewRating: expectedNewRating,
                         expDidChangeProtectionCalled: expDidChangeProtectionCalled,
                         expectedNewProtection: expectedNewProtection)
        let initData = ComposeViewModel.InitData(composeMode: .normal)
        if ignoreDelegateCallsWhileInitializing {
            testee = ComposeViewModel.ComposeViewModelState(initData: initData, delegate: nil)
            testee?.delegate = testDelegate
        } else {
            testee = ComposeViewModel.ComposeViewModelState(initData: initData,
                                                            delegate: testDelegate)
        }
    }

    private func setupSimpleTestee() {
        let initData = ComposeViewModel.InitData()
        testee = ComposeViewModel.ComposeViewModelState(initData: initData, delegate: nil)
    }

    class TestDelegate: ComposeViewModelStateDelegate {
        var ignoreAll = false

        let expDidChangeValidationStateToCalled: XCTestExpectation?
        let expectedStateIsValid: Bool?

        let expDidChangePEPRatingToCalled: XCTestExpectation?
        let expectedNewRating: PEP_rating?

        let expDidChangeProtectionCalled: XCTestExpectation?
        let expectedNewProtection: Bool?

        init(expDidChangeValidationStateToCalled: XCTestExpectation? = nil,
             expectedStateIsValid: Bool? = nil,
             expDidChangePEPRatingToCalled: XCTestExpectation? = nil,
             expectedNewRating: PEP_rating? = nil,
             expDidChangeProtectionCalled: XCTestExpectation? = nil,
             expectedNewProtection: Bool? = nil) {
            self.expDidChangeValidationStateToCalled = expDidChangeValidationStateToCalled
            self.expectedStateIsValid = expectedStateIsValid
            self.expDidChangePEPRatingToCalled = expDidChangePEPRatingToCalled
            self.expectedNewRating = expectedNewRating
            self.expDidChangeProtectionCalled = expDidChangeProtectionCalled
            self.expectedNewProtection = expectedNewProtection
        }

        func composeViewModelState(_ composeViewModelState: ComposeViewModel.ComposeViewModelState,
                                   didChangeValidationStateTo isValid: Bool) {
            guard let exp = expDidChangeValidationStateToCalled, !ignoreAll  else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedStateIsValid {
                XCTAssertEqual(isValid, expected)
            }
        }

        func composeViewModelState(_ composeViewModelState: ComposeViewModel.ComposeViewModelState,
                                   didChangePEPRatingTo newRating: PEP_rating) {
            guard let exp = expDidChangePEPRatingToCalled, !ignoreAll  else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedNewRating {
                XCTAssertEqual(newRating, expected)
            }
        }

        func composeViewModelState(_ composeViewModelState: ComposeViewModel.ComposeViewModelState,
                                   didChangeProtection newValue: Bool) {
            guard let exp = expDidChangeProtectionCalled, !ignoreAll else {
                // We ignore called or not
                return
            }
            exp.fulfill()
            if let expected = expectedNewProtection {
                XCTAssertEqual(newValue, expected)
            }
        }
    }
}
