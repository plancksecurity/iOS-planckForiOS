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

class ComposeViewModelStateTest: XCTestCase {

    /*
     private(set) var initData: InitData?
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

     public private(set) var bccWrapped = true

     weak var delegate: ComposeViewModelStateDelegate?

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

    class Delegate: ComposeViewModelStateDelegate {
        func composeViewModelState(_ composeViewModelState: ComposeViewModel.ComposeViewModelState,
                                   didChangeValidationStateTo isValid: Bool) {
            fatalError()
        }

        func composeViewModelState(_ composeViewModelState: ComposeViewModel.ComposeViewModelState,
                                   didChangePEPRatingTo newRating: PEP_rating) {
            fatalError()
        }

        func composeViewModelState(_ composeViewModelState: ComposeViewModel.ComposeViewModelState,
                                   didChangeProtection newValue: Bool) {
            fatalError()
        }
    }

}
