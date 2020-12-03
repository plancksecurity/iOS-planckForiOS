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

        public var pEpProtection: Bool {
            set {
                let oldValue = backingMessage.pEpProtected
                backingMessage.pEpProtected = (isForceUnprotectedDueToBccSet) ? false : newValue
                if backingMessage.pEpProtected != oldValue {
                    delegate?.composeViewModelState(self, didChangeProtection: pEpProtection)
                }
            }
            get {
                return backingMessage.pEpProtected
            }
        }

        public private(set) var bccWrapped = true

        weak var delegate: ComposeViewModelStateDelegate?

        //Recipients
        var toRecipients: [Identity] {
            get {
                return backingMessage.to.allObjects
            }
            set {
                backingMessage.replaceTo(with: newValue)
                edited = true
                validate()
            }
        }

        var ccRecipients: [Identity] {
            get {
                return backingMessage.cc.allObjects
            }
            set {
                backingMessage.replaceCc(with: newValue)
                edited = true
                validate()
            }
        }

        var bccRecipients: [Identity] {
            get {
                return backingMessage.bcc.allObjects
            }
            set {
                backingMessage.replaceBcc(with: newValue)
                edited = true
                validate()
            }
        }

        var from: Identity? {
            get {
                return backingMessage.from
            }
            set {
                // TODO: Move the backing message to another folder
                backingMessage.from = newValue
                edited = true
                validate()
            }
        }

        var subject: String {
            get {
                // TODO: Must that really be set to " " for the UI to function properly?
                return backingMessage.shortMessage ?? ""
            }
            set {
                backingMessage.shortMessage = newValue
                edited = true
            }
        }

        var bodyPlaintext: String {
            get {
                return backingMessage.longMessage ?? ""
            }
            set {
                backingMessage.longMessage = newValue
                edited = true
            }
        }

        var _bodyText = NSAttributedString(string: "")
        var bodyText: NSAttributedString {
            get {
                return _bodyText
            }
            set {
                _bodyText = newValue
                edited = true
            }
        }

        var inlinedAttachments = [Attachment]()

        var nonInlinedAttachments = [Attachment]() {
            didSet {
                edited = true
            }
        }

        /// The message that contains all the data
        let backingMessage: Message

        init(initData: InitData? = nil, delegate: ComposeViewModelStateDelegate? = nil) {
            self.initData = initData
            self.delegate = delegate

            backingMessage = Message.newOutgoingMessage()

            setup()

            edited = false
        }

        public func makeSafe(forSession session: Session,
                             cloneAttachments: Bool = false) -> ComposeViewModelState {
            let newValue = ComposeViewModelState(initData: initData, delegate: nil)

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

        private func setup() {
            guard let initData = initData else {
                Log.shared.errorAndCrash("No data")
                return
            }

            backingMessage.replaceTo(with: initData.toRecipients)
            backingMessage.replaceCc(with: initData.ccRecipients)
            backingMessage.replaceBcc(with: initData.bccRecipients)
            bccWrapped = ccRecipients.isEmpty && bccRecipients.isEmpty
            backingMessage.from = initData.from
            backingMessage.shortMessage = initData.subject ?? " "

            backingMessage.pEpProtected = initData.pEpProtection

            inlinedAttachments = initData.inlinedAttachments
            nonInlinedAttachments = initData.nonInlinedAttachments

            setInitialAccount()
        }

        private func validateForSending() {
            let atLeastOneRecipientIsSet =
                (!toRecipients.isEmpty ||
                    !ccRecipients.isEmpty ||
                    !bccRecipients.isEmpty)
            let fromIsSet = from != nil

            isValidatedForSending = atLeastOneRecipientIsSet && fromIsSet
        }

        /// Provides the backing message with an account so saving is safe.
        private func setInitialAccount() {
            if let fromId = initData?.from {
                guard let account = Account.by(address: fromId.address) else {
                    Log.shared.errorAndCrash(message: "Compose from email without matching account")
                    return
                }
                setupBackingMessage(withAccount: account)
            } else {
                guard let account = Account.defaultAccount() else {
                    Log.shared.errorAndCrash(message: "Compose without defined default account")
                    return
                }
                setupBackingMessage(withAccount: account)
            }
        }

        /// Sets the backing message up with the given account, that is, sets `from`, the parent folder, among others.
        private func setupBackingMessage(withAccount: Account) {
            setFromOfBackingMessage(toAccount: withAccount)
            setParentOfBackingMessage(toAccount: withAccount)
        }

        /// Sets the `from` of the backing message to the given account's identity.
        private func setFromOfBackingMessage(toAccount: Account) {
            backingMessage.from = toAccount.user
        }

        /// Sets the parent folder of the backing message to a folder from the given account.
        private func setParentOfBackingMessage(toAccount: Account) {
            guard let draftsFolder = Folder.by(account: toAccount, folderType: .drafts) else {
                Log.shared.errorAndCrash(message: "Account without drafts folder")
                return
            }
            backingMessage.parent = draftsFolder
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
