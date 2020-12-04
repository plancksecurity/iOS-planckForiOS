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
                               didChangePEPRatingTo newRating: Rating)

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
        public private(set) var rating = Rating.undefined {
            didSet {
                if rating != oldValue {
                    delegate?.composeViewModelState(self, didChangePEPRatingTo: rating)
                }
            }
        }

        private var _pEpProtection = true
        public var pEpProtection: Bool {
            set {
                let oldValue = _pEpProtection
                _pEpProtection = (isForceUnprotectedDueToBccSet) ? false : newValue
                if _pEpProtection != oldValue {
                    delegate?.composeViewModelState(self, didChangeProtection: pEpProtection)
                    draftMessageSave()
                }
            }
            get {
                return _pEpProtection
            }
        }

        public private(set) var bccWrapped = true

        weak var delegate: ComposeViewModelStateDelegate?

        //Recipients
        var toRecipients = [Identity]() {
            didSet {
                edited = true
                validate()
                draftMessageSave()
            }
        }
        var ccRecipients = [Identity]() {
            didSet {
                edited = true
                validate()
                draftMessageSave()
            }
        }
        var bccRecipients = [Identity]() {
            didSet {
                edited = true
                validate()
                draftMessageSave()
            }
        }

        var from: Identity? {
            didSet {
                edited = true
                validate()
                draftMessageSave()
            }
        }

        var subject = " " {
            didSet {
                edited = true
                draftMessageSave()
            }
        }

        var bodyPlaintext = "" {
            didSet {
                edited = true
                draftMessageSave()
            }
        }

        var bodyText = NSAttributedString(string: "") {
            didSet {
                edited = true
                draftMessageSave()
            }
        }

        var inlinedAttachments = [Attachment]()

        var nonInlinedAttachments = [Attachment]() {
            didSet {
                edited = true
                draftMessageSave()
            }
        }

        /// If true, the state gets saved to a drafts message periodically.
        /// Set to false for states that are just used to pass around data.
        let isBackedByDraftMessage: Bool

        /// The message that gets saved periodically with current data
        var draftMessage: Message?

        init(initData: InitData? = nil,
             delegate: ComposeViewModelStateDelegate? = nil,
             isBackedByDraftMessage: Bool) {
            self.initData = initData
            self.delegate = delegate
            self.isBackedByDraftMessage = isBackedByDraftMessage

            setup()
            edited = false
        }

        public func makeSafe(forSession session: Session,
                             cloneAttachments: Bool = false) -> ComposeViewModelState {
            let newValue = ComposeViewModelState(initData: initData,
                                                 delegate: nil,
                                                 isBackedByDraftMessage: false)

            newValue.toRecipients = Identity.makeSafe(toRecipients, forSession: session)
            newValue.ccRecipients = Identity.makeSafe(ccRecipients, forSession: session)
            newValue.bccRecipients = Identity.makeSafe(bccRecipients, forSession: session)
            if let from = from {
                newValue.from = Identity.makeSafe(from, forSession: session)
            }
            newValue.inlinedAttachments = Attachment.clone(attachmnets: inlinedAttachments, //!!!: Looks very wrong to me. Why clone? should make save?!
                                                           for: session)
            newValue.nonInlinedAttachments = Attachment.clone(attachmnets: nonInlinedAttachments, //BUFF: Looks very wrong to me. Why clone? should make save?!
                                                              for: session)
            newValue.isValidatedForSending = isValidatedForSending
            newValue.pEpProtection = pEpProtection
            newValue.bccWrapped = bccWrapped
            newValue.subject = subject
            newValue.bodyPlaintext = bodyPlaintext
            newValue.bodyText = bodyText
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
            updatePepRating()
            validateForSending()
        }

        /// Delete the drafts backup message, if it was created
        public func deleteDraftMessage() {
            if let theDraftMessage = draftMessage {
                let theDraft = Message.makeSafe(theDraftMessage, forSession: Session.main)
                theDraft.imapMarkDeleted()
            }
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
            subject = initData.subject ?? " "

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

        // MARK: - Save Message

        /// - Returns: A suitable account for saving a draft message, on the main session.
        private func draftMessageAccount() -> Account? {
            if let fromId = initData?.from {
                guard let account = Account.by(address: fromId.address) else {
                    Log.shared.errorAndCrash(message: "Compose from email without matching account")
                    return nil
                }
                return account
            } else {
                guard let account = Account.defaultAccount() else {
                    Log.shared.errorAndCrash(message: "Compose without defined default account")
                    return nil
                }
                return account
            }
        }

        /// Saves the save message.
        private func draftMessageSave() {
            // Ignore the auto-save if not explicitly configured
            guard isBackedByDraftMessage else {
                return
            }

            guard let account = draftMessageAccount() else {
                Log.shared.errorAndCrash("No account for saving a draft message")
                return
            }

            let session = account.session

            guard let draftsFolder = Folder.by(account: account,
                                               folderType: .drafts)?.safeForSession(session) else {
                Log.shared.errorAndCrash("No drafts folder")
                return
            }

            let safeState = makeSafe(forSession: session)

            let body = safeState.bodyText.toHtml(inlinedAttachments: inlinedAttachments)
            let bodyPlainText = body.plainText
            let bodyHtml = body.html ?? ""

            if draftMessage == nil {
                draftMessage = Message.newOutgoingMessage()
            }

            guard let theDraftMessage = draftMessage else {
                Log.shared.errorAndCrash("No way this is nil")
                return
            }

            // TODO: Can that be switched without problems in case the account changes?
            theDraftMessage.parent = draftsFolder

            theDraftMessage.from = safeState.from
            theDraftMessage.replaceTo(with: safeState.toRecipients)
            theDraftMessage.replaceCc(with: safeState.ccRecipients)
            theDraftMessage.replaceBcc(with: safeState.bccRecipients)
            theDraftMessage.shortMessage = safeState.subject
            theDraftMessage.longMessage = bodyPlainText
            theDraftMessage.longMessageFormatted = !bodyHtml.isEmpty ? bodyHtml : nil
            theDraftMessage.replaceAttachments(with: safeState.inlinedAttachments + safeState.nonInlinedAttachments)
            theDraftMessage.pEpProtected = safeState.pEpProtection
            if !safeState.pEpProtection {
                let unprotectedRating = Rating.unencrypted
                theDraftMessage.setOriginalRatingHeader(rating: unprotectedRating)
                theDraftMessage.pEpRatingInt = unprotectedRating.toInt()
            } else {
                theDraftMessage.setOriginalRatingHeader(rating: rating)
                theDraftMessage.pEpRatingInt = rating.toInt()
            }

            theDraftMessage.imapFlags.seen = true

            session.commit()
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

//    private func calculatePepRating(from: Identity, //BUFF: unused
//                                    to: [Identity],
//                                    cc: [Identity],
//                                    bcc: [Identity]) -> PEPRating {
//
//        guard !isForceUnprotectedDueToBccSet else {
//            return .unencrypted
//        }
//
//        let session = Session.main
//        let safeFrom = from.safeForSession(session)
//        let safeTo = Identity.makeSafe(to, forSession: session)
//        let safeCc = Identity.makeSafe(cc, forSession: session)
//        let safeBcc = Identity.makeSafe(bcc, forSession: session)
//        let pEpsession = PEPSession()
//        let rating = pEpsession.outgoingMessageRating(from: safeFrom,
//                                                      to: safeTo,
//                                                      cc: safeCc,
//                                                      bcc: safeBcc)
//
//        return rating
//    }

    private func updatePepRating() {
        guard !isForceUnprotectedDueToBccSet else {
            rating = .unencrypted
            return
        }

        guard let from = from else {
            rating = .undefined
            return
        }

        let session = Session.main
        let safeFrom = from.safeForSession(session)
        let safeTo = Identity.makeSafe(toRecipients, forSession: session)
        let safeCc = Identity.makeSafe(ccRecipients, forSession: session)
        let safeBcc = Identity.makeSafe(bccRecipients, forSession: session)

        Rating.outgoingMessageRating(from: safeFrom, to: safeTo, cc: safeCc, bcc: safeBcc) {
            [weak self] outgoingRating in

            guard let me = self else {
                // Valid case. Compose might have been dismissed.
                return
            }
            DispatchQueue.main.async {
                me.rating = outgoingRating
            }
        }
    }


}

// MARK: - Handshake

extension ComposeViewModel.ComposeViewModelState {

    public func canHandshake(completion: @escaping (Bool)->Void) {
        handshakeActionCombinations { (handshakeActionCombinations) in
            completion(!handshakeActionCombinations.isEmpty)
        }
    }

    private func handshakeActionCombinations(completion: @escaping ([TrustManagementUtil.HandshakeCombination])->Void) {
        if let from = from {
            var allIdenties = toRecipients
            allIdenties.append(from)
            allIdenties.append(contentsOf: ccRecipients)
            allIdenties.append(contentsOf: bccRecipients)
            TrustManagementUtil().handshakeCombinations(identities: allIdenties, completion: completion)
        } else {
            completion([])
        }
    }
}
