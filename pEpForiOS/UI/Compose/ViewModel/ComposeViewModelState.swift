//
//  ComposeViewModelState.swift
//  pEp
//
//  Created by Andreas Buff on 15.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

protocol ComposeViewModelStateDelegate: class {
    func composeViewModelState(_ composeViewModelState: ComposeViewModel.ComposeViewModelState,
                               didChangeValidationStateTo isValid: Bool)

    func composeViewModelState(_ composeViewModelState: ComposeViewModel.ComposeViewModelState,
                               didChangePEPRatingTo newRating: PEPRating)

    func composeViewModelState(_ composeViewModelState: ComposeViewModel.ComposeViewModelState,
                               didChangeProtection newValue: Bool)
}

extension ComposeViewModel {

/// Wraps bookholding properties
    class ComposeViewModelState {
        private(set) var initData: InitData?
        private var isValidatedForSending = false {
            didSet {
                delegate?.composeViewModelState(self,
                                                didChangeValidationStateTo: isValidatedForSending)
            }
        }
        public private(set) var edited = false
        public private(set) var rating = PEPRatingUndefined {
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

        var inlinedAttachments = [Attachment]()

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
                Logger.frontendLogger.errorAndCrash("No data")
                return
            }
            toRecipients = initData.toRecipients
            ccRecipients = initData.ccRecipients
            bccRecipients = initData.bccRecipients
            bccWrapped = ccRecipients.isEmpty && bccRecipients.isEmpty
            from = initData.from
            subject = initData.subject

            pEpProtection = initData.pEpProtection

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
}

// MARK: - pEp Protections

extension ComposeViewModel.ComposeViewModelState {

    public func userCanToggleProtection() -> Bool {
        if isForceUnprotectedDueToBccSet {
            return false
        }
        let outgoingRatingColor = rating.pEpColor()
        return outgoingRatingColor == PEPColor_yellow || outgoingRatingColor == PEPColor_green
    }
}

// MARK: - PEP_Color

extension ComposeViewModel.ComposeViewModelState {
    
    private var isForceUnprotectedDueToBccSet: Bool {
        return bccRecipients.count > 0
    }

    private func calculatePepRating() {
        guard !isForceUnprotectedDueToBccSet && pEpProtection else {
            rating = PEPRatingUnencrypted
            return
        }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let me = self else {
                // That is a valid case. Compose view is gone before this block started to run.
                return
            }
            let newRating: PEPRating
            let session = PEPSession()
            if let from = me.from {
                newRating = session.outgoingMessageRating(from: from,
                                                       to: me.toRecipients,
                                                       cc: me.ccRecipients,
                                                       bcc: me.bccRecipients)
            } else {
                newRating = PEPRatingUndefined
            }
            DispatchQueue.main.async {
                me.rating = newRating
            }
        }
    }
}

// MARK: - Handshake

extension ComposeViewModel.ComposeViewModelState {

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
