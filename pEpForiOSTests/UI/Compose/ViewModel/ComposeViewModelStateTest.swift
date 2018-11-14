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
    private var testDelegate: TestDelegate?
    var testee: ComposeViewModel.ComposeViewModelState?

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
        let initData = ComposeViewModel.InitData()
        testee = ComposeViewModel.ComposeViewModelState(initData: initData, delegate: nil)
        guard let wrapped = testee?.bccWrapped else {
            XCTFail()
            return
        }
        XCTAssertTrue(wrapped)
    }

    func testBccWrapped_unwrapped() {
        let initData = ComposeViewModel.InitData()
        testee = ComposeViewModel.ComposeViewModelState(initData: initData, delegate: nil)
        testee?.setBccUnwrapped()
        guard let wrapped = testee?.bccWrapped else {
            XCTFail()
            return
        }
        XCTAssertFalse(wrapped)
    }

    /*

     private var isValidatedForSending = false {
     didSet {
     delegate?.composeViewModelState(self,
     didChangeValidationStateTo: isValidatedForSending)
     }
     }
     public private(set) var edited = false
     public private(set) var rating = PEP_rating_undefined {
     didSet {
     if rating != oldValue {
     delegate?.composeViewModelState(self, didChangePEPRatingTo: rating)
     }
     }
     }

     public var pEpProtection = true {
     didSet {
     if pEpProtection != oldValue {
     delegate?.composeViewModelState(self, didChangeProtection: pEpProtection)
     }
     }
     }




             //Recipients
             var toRecipients = [Identity]() {
             didSet {
             edited = true
             validate()
             }
     }
     var ccRecipients = [Identity]() {
     didSet {
     edited = true
     validate()
     }
     }
     var bccRecipients = [Identity]() {
     didSet {
     edited = true
     validate()
     }
     }

     var from: Identity? {
     didSet {
     edited = true
     validate()
     }
     }

     var subject = " " {
     didSet {
     edited = true
     }
     }

     var bodyPlaintext = "" {
     didSet {
     edited = true
     }
     }

     var bodyHtml = "" {
     didSet {
     edited = true
     }
     }

     var inlinedAttachments = [Attachment]() {
     didSet {
     edited = true
     }
     }

     var nonInlinedAttachments = [Attachment]() {
     didSet {
     edited = true
     }
     }

     init(initData: InitData? = nil, delegate: ComposeViewModelStateDelegate? = nil) {
     self.initData = initData
     self.delegate = delegate
     setup()
     edited = false
     }

     public func setBccUnwrapped() {
     bccWrapped = false
     }

     public func validate() {
     calculatePepRating()
     validateForSending()
     }
     */

    // MARK: - HELPER

    class TestDelegate: ComposeViewModelStateDelegate {
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
            guard let exp = expDidChangeValidationStateToCalled else {
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
            guard let exp = expDidChangePEPRatingToCalled else {
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
            guard let exp = expDidChangeProtectionCalled else {
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
