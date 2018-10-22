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
    let initData: InitData?
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

extension ComposeViewModelState {

    private final func message() -> Message? {
        guard let from = from,
            let account = Account.by(address: from.address) else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString:
                    "We have a problem here getting the senders account.")
                return nil
        }
        guard let f = Folder.by(account: account, folderType: .outbox) else {
            Log.shared.errorAndCrash(component: #function, errorString: "No outbox")
            return nil
        }

        let message = Message(uuid: MessageID.generate(), parentFolder: f)
        message.from = from
        message.to = toRecipients
        message.cc = ccRecipients
        message.bcc = bccRecipients
        message.shortMessage = subject
        message.attachments = inlinedAttachments + nonInlinedAttachments
        message.pEpProtected = pEpProtection

        //IOS-1369: BODY!
        
        /*
         let (markdownText, attachments) = cell.textView.attributedText.convertToMarkDown()
         // Set longMessage (plain text)
         if inlinedAttachments.count > 0 {
         message.longMessage = markdownText
         message.attachments = message.attachments + attachments
         } else {
         message.longMessage = cell.textView.text
         }
         // Set longMessageFormatted (HTML)
         var longMessageFormatted = markdownText.markdownToHtml()
         if let safeHtml = longMessageFormatted {
         longMessageFormatted = wrappedInHtmlStyle(toWrap: safeHtml)
         }
         message.longMessageFormatted = longMessageFormatted
         } else if let fm = cell.fieldModel, fm.type == .subject {
         message.shortMessage = cell.textView.text.trimmingCharacters(
         in: .whitespacesAndNewlines).replaceNewLinesWith(" ")
         }
         */



        //IOS-1369: todo:
//        if composeMode == .replyFrom || composeMode == .replyAll,
//            let om = originalMessage {
//            // According to https://cr.yp.to/immhf/thread.html
//            var refs = om.references
//            refs.append(om.messageID)
//            if refs.count > 11 {
//                refs.remove(at: 1)
//            }
//            message.references = refs
//        }



        message.setOriginalRatingHeader(rating: rating) // This should be moved. Algo did change. Currently we set it here and remove it when sending. We should set it where it should be set instead. Probalby in append OP
        return message
    }
}
