//
//  ComposeViewModelState.swift
//  pEp
//
//  Created by Andreas Buff on 15.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox
import PEPObjCAdapterFramework

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
        public private(set) var rating = PEPRating.undefined {
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

        deinit {
            inlinedAttachments.forEach {
                if  $0.message == nil {
                    $0.delete()
                }
            }
            nonInlinedAttachments.forEach {
                if  $0.message == nil {
                    $0.delete()
                }
            }
        }

        public func makeSafe(forSession session: Session) -> ComposeViewModelState {
            let newValue = ComposeViewModelState(initData: initData, delegate: nil)

            newValue.toRecipients = Identity.makeSafe(toRecipients, forSession: session)
            newValue.ccRecipients = Identity.makeSafe(ccRecipients, forSession: session)
            newValue.bccRecipients = Identity.makeSafe(bccRecipients, forSession: session)
            if let from = from {
                newValue.from = Identity.makeSafe(from, forSession: session)
            }
            newValue.inlinedAttachments = Attachment.makeSafe(inlinedAttachments,
                                                              forSession: session)
            newValue.nonInlinedAttachments = Attachment.makeSafe(nonInlinedAttachments,
                                                                 forSession: session)


            newValue.isValidatedForSending = isValidatedForSending
            newValue.pEpProtection = pEpProtection
            newValue.bccWrapped = bccWrapped
            newValue.subject = subject
            newValue.bodyPlaintext = bodyPlaintext
            newValue.bodyHtml = bodyHtml



            newValue.isValidatedForSending = isValidatedForSending
            newValue.rating = rating
            newValue.edited = edited
            newValue.delegate = delegate

            return newValue
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
                Log.shared.errorAndCrash("No data")
                return
            }
            toRecipients = initData.toRecipients
            ccRecipients = initData.ccRecipients
            bccRecipients = initData.bccRecipients
            bccWrapped = ccRecipients.isEmpty && bccRecipients.isEmpty
            from = initData.from
            subject = initData.subject

            pEpProtection = initData.pEpProtection

            inlinedAttachments = initData.inlinedAttachments
            nonInlinedAttachments = initData.nonInlinedAttachments
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
        return outgoingRatingColor == .yellow || outgoingRatingColor == .green
    }
}

// MARK: - PEP_Color

extension ComposeViewModel.ComposeViewModelState {
    
    private var isForceUnprotectedDueToBccSet: Bool {
        return bccRecipients.count > 0
    }

    private func calculatePepRating() {
        guard !isForceUnprotectedDueToBccSet else {
            rating = .unencrypted
            return
        }

        var newRating = PEPRating.undefined
        guard let from = from else {
            rating = newRating
            return
        }

        /*
        //!!!: In tests (ComposeViewModelStateTest) this block is triggered by setup and modt test, but never  executed:
        DEBUG: will setup
        DEBUG: before going to background
        DEBUG: on background
        DEBUG: did setup
        DEBUG: will tearDown
        DEBUG: did tearDown
        DEBUG: will setup
        DEBUG: before going to background
        DEBUG: did setup
        DEBUG: on background
 */

//        print("COMPOSE: before going to background")

        let session = Session()
        let safeFrom = from.safeForSession(session)
        let safeTo = Identity.makeSafe(toRecipients, forSession: session)
        let safeCc = Identity.makeSafe(ccRecipients, forSession: session)
        let safeBcc = Identity.makeSafe(bccRecipients, forSession: session)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in //HERE:
            //!!!:
//            print("COMPOSE: on background")
            guard let me = self else {
                // That is a valid case. Compose view is gone before this block started to run.
                return
            }

            session.performAndWait {
                let pEpsession = PEPSession()
                newRating = pEpsession.outgoingMessageRating(from: safeFrom,
                                                             to: safeTo,
                                                             cc: safeCc,
                                                             bcc: safeBcc)
            }
            //!!!:
//            print("COMPOSE: did outgoingMessageRating")
            DispatchQueue.main.async {
                me.rating = newRating
                //!!!:
//                print("COMPOSE: did newRating")
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
