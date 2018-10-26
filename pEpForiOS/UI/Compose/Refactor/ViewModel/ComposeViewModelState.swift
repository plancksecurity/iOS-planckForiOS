//
//  ComposeViewModelState.swift
//  pEp
//
//  Created by Andreas Buff on 15.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

protocol ComposeViewModelStateDelegate: class {
    func composeViewModelState(_ composeViewModelState: ComposeViewModelState,
                               didChangeValidationStateTo isValid: Bool)

    func composeViewModelState(_ composeViewModelState: ComposeViewModelState,
                               didChangePEPRatingTo newRating: PEP_rating)

    func composeViewModelState(_ composeViewModelState: ComposeViewModelState,
                               didChangeProtection newValue: Bool)


}
//IOS-1369: wrap in extention when done to not polute the namespace
//extension ComposeViewModel {

/// Wraps bookholding properties
class ComposeViewModelState {
    private(set) var initData: InitData?
    private var edited = false
    private var isValidatedForSending = false {
        didSet {
                delegate?.composeViewModelState(self,
                                                didChangeValidationStateTo: isValidatedForSending)
        }
    }

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

    var subject = "" {
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

    private func setup() {
        guard let initData = initData else {
            Log.shared.errorAndCrash(component: #function, errorString: "No data")
            return
        }
        toRecipients = initData.toRecipients
        ccRecipients = initData.ccRecipients
        bccRecipients = initData.bccRecipients
        bccWrapped = ccRecipients.isEmpty && bccRecipients.isEmpty
        from = initData.from
        subject = initData.subject ?? " " // Set space to work around autolayout first baseline not recognized
        //            body = initD //IOS-1369: TODO
//        bodyPlaintext = initData.bodyPlaintext
//        bodyHtml = initData.bodyHtml

        inlinedAttachments =  initData.inlinedAttachments
        nonInlinedAttachments =  initData.nonInlinedAttachments
    }

    private func validateForSending() {
        let atLeastOneRecipientIsSet =
            (!toRecipients.isEmpty ||
            !ccRecipients.isEmpty ||
            !bccRecipients.isEmpty)
        let fromIsSet = from != nil

        isValidatedForSending = atLeastOneRecipientIsSet && fromIsSet
    }
}

// MARK: - pEp Protections

extension ComposeViewModelState {

    public func canToggleProtection() -> Bool {
        if isForceUnprotectedDueToBccSet {
            return false
        }
        let outgoingRatingColor = rating.pEpColor()
        return outgoingRatingColor == PEP_color_yellow || outgoingRatingColor == PEP_color_green
    }
}

// MARK: - PEP_Color

extension ComposeViewModelState {
    //NEW

    private var isForceUnprotectedDueToBccSet: Bool {
        return bccRecipients.count > 0
    }

    private func calculatePepRating() {
        guard !isForceUnprotectedDueToBccSet else {
            rating = PEP_rating_unencrypted
            return
        }
        let session = PEPSession()
        if let from = from {
            rating = session.outgoingMessageRating(from: from,
                                                   to: toRecipients,
                                                   cc: ccRecipients,
                                                   bcc: bccRecipients)
        } else {
            rating = PEP_rating_undefined
        }
    }
}

// MARK: - Handshake

extension ComposeViewModelState {

    public func canHandshake() -> Bool {
        return !handshakeActionCombinations().isEmpty
    }

    private func handshakeActionCombinations() -> [HandshakeCombination] {
        if let from = from {
            var allIdenties = toRecipients
            allIdenties.append(from)
            allIdenties.append(contentsOf: ccRecipients)
            allIdenties.append(contentsOf: bccRecipients)
            return Message.handshakeActionCombinations(identities: allIdenties)
        } else {
            return []
        }
    }
}
