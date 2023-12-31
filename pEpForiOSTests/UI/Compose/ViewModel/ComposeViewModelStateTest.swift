
//
//  ComposeViewModelStateTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 14.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

class ComposeViewModelStateTest: AccountDrivenTestBase {
    private var testDelegate: TestDelegate?
    var testee: ComposeViewModel.ComposeViewModelState?
    var draftedMessageAllButBccSet: Message?
    var someone: Identity!

    override func setUp() {
        //!!!:
        print("DEBUG: will setup")
        super.setUp()
        someone = Identity(address: "someone@someone.someone")
        let drafts = Folder(name: "Inbox", parent: nil, account: account, folderType: .drafts)
        drafts.session.commit()
        let msg = Message(uuid: UUID().uuidString, parentFolder: drafts)
        msg.from = account.user
        msg.replaceTo(with: [account.user, someone])
        msg.replaceCc(with: [someone])
        msg.shortMessage = "shortMessage"
        msg.longMessage = "longMessage"
        msg.longMessageFormatted = "longMessageFormatted"
        msg.replaceAttachments(with: [Attachment(data: Data(),
                                                 mimeType: "image/jpg",
                                                 contentDisposition: .attachment)])
        msg.appendToAttachments(Attachment(data: Data(),
                                           mimeType: "image/jpg",
                                           contentDisposition: .inline))
        msg.session.commit()
        draftedMessageAllButBccSet = msg

        setupSimpleTestee()
        //!!!:
        print("DEBUG: did setup")
        sleep(2)
    }

    override func tearDown() {
        //!!!:
        print("DEBUG: will tearDown")
        testee = nil
        draftedMessageAllButBccSet = nil
        testDelegate = nil
        super.tearDown()
        //!!!:
        print("DEBUG: did tearDown")
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
        //!!!:
        print("DEBUG: test start")
        testee?.ccRecipients = [someone]
        guard let edited = testee?.edited else {
            XCTFail()
            return
        }
        XCTAssertTrue(edited)
        //!!!:
        print("DEBUG: test end")
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
        testee?.bodyText = NSAttributedString(string: #function)
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

    // MARK: - HELPER

    private func assert(ignoreDelegateCallsWhileInitializing: Bool = true,
                        didChangeValidationStateMustBeCalled: Bool? = nil,
                        expectedStateIsValid: Bool? = nil,
                        didChangePEPRatingMustBeCalled: Bool? = nil,
                        expectedNewRating: Rating? = nil,
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
        let expectedNewRating: Rating?

        let expDidChangeProtectionCalled: XCTestExpectation?
        let expectedNewProtection: Bool?

        init(expDidChangeValidationStateToCalled: XCTestExpectation? = nil,
             expectedStateIsValid: Bool? = nil,
             expDidChangePEPRatingToCalled: XCTestExpectation? = nil,
             expectedNewRating: Rating? = nil,
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
                                   didChangePEPRatingTo newRating: Rating) {
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
