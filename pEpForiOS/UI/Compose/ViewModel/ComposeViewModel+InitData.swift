//
//  ComposeViewModel+InitData.swift
//  pEp
//
//  Created by Andreas Buff on 15.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

// MARK: - InitData

extension ComposeViewModel {
    /// Wraps properties used for initial setup
    struct InitData {
        /// Recipient to set as "To:".
        /// Is ignored if a originalMessage is set.
        public let prefilledTo: Identity?

        /// Sender to set as "From:".
        /// If null it will be calculated from compose mode or set as default user.
        public let prefilledFrom: Identity?

        /// Original message to compute content and recipients from (e.g. a message we reply to).
        private var _cloneMessage: Message? = nil
        public var cloneMessage: Message? {
            get {
                guard !(_cloneMessage?.isDeleted ?? true) else {
                    // Makes sure we do not access properties af a messages that has been deleted
                    // in the DB.
                    return nil
                }
                return _cloneMessage
            }
            set {
                _cloneMessage = newValue
            }
        }

        public let composeMode: ComposeUtil.ComposeMode

        /// Whether or not the original message is in Drafts or Outbox
        var isDraftsOrOutbox: Bool {
            return isDrafts || isOutbox
        }

        /// Whether or not the original message is in Drafts folder
        var isDrafts: Bool {
            if let om = cloneMessage {
                return om.parent.folderType == .drafts
            }
            return false
        }

        /// Whether or not the original message is in Outbox
        var isOutbox: Bool {
            if let om = cloneMessage {
                return om.parent.folderType == .outbox
            }
            return false
        }

        var pEpProtection: Bool {
            return cloneMessage?.pEpProtected ?? true
        }

        var from: Identity? {
            return prefilledFrom ?? ComposeUtil.initialFrom(composeMode: composeMode,
                                           originalMessage: cloneMessage)
        }

        var toRecipients: [Identity] {
            if let om = cloneMessage {
                return ComposeUtil.initialTos(composeMode: composeMode, originalMessage: om)
            } else if let presetTo = prefilledTo {
                return [presetTo]
            }
            return []
        }

        var ccRecipients: [Identity] {
            guard let om = cloneMessage else {
                return []
            }
            return ComposeUtil.initialCcs(composeMode: composeMode, originalMessage: om)
        }

        var bccRecipients: [Identity] {
            guard let om = cloneMessage else {
                return []
            }
            return ComposeUtil.initialBccs(composeMode: composeMode, originalMessage: om)
        }

        var subject = " "

        var bodyPlaintext = ""
        var bodyHtml: NSAttributedString?

        public var nonInlinedAttachments = [Attachment]()
        public var inlinedAttachments = [Attachment]()

        init(withPrefilledToRecipient prefilledTo: Identity? = nil,
             prefilledFromSender prefilledFrom: Identity? = nil,
             orForOriginalMessage om: Message? = nil,
             composeMode: ComposeUtil.ComposeMode? = nil) {

            let cloneMessage = om?.cloneWithZeroUID(session: Session.main)
            self.composeMode = composeMode ?? ComposeUtil.ComposeMode.normal
            self.prefilledTo = cloneMessage == nil ? prefilledTo : nil
            self.prefilledFrom = prefilledFrom
            self.cloneMessage = cloneMessage
            self.inlinedAttachments = ComposeUtil.initialAttachments(composeMode: self.composeMode,
                                                                     contentDisposition: .inline,
                                                                     originalMessage: cloneMessage)
            self.nonInlinedAttachments = ComposeUtil.initialAttachments(composeMode: self.composeMode,
                                                                        contentDisposition: .attachment,
                                                                        originalMessage: cloneMessage)
            setupInitialSubject()
            setupInitialBody()
        }

        /// Delte the cloned message used to get all the message data
        ///
        /// Note: Must be call after using init data
        ///
        func deleteClonedMessage() {
            guard let cloneMessage = _cloneMessage else {
                return
            }
            cloneMessage.delete()
        }

        mutating private func setupInitialSubject() {
            guard let om = cloneMessage else {
                // We have no original message. That's OK for compose mode .normal.
                return
            }
            switch composeMode {
            case .replyFrom,
                 .replyAll:
                subject = ReplyUtil.replySubject(message: om)
            case .forward:
                subject = ReplyUtil.forwardSubject(message: om)
            case .normal:
                if isDraftsOrOutbox {
                    subject = om.shortMessage ?? " "
                }
                // .normal is intentionally ignored here for other folder types
            }
        }

        mutating private func setupInitialBody() {
            guard let om = cloneMessage else {
                // We have no original message. That's OK for compose mode .normal.
                return
            }
            switch composeMode {
            case .replyFrom:
                setInitialBody(text: ReplyUtil.quotedMessageText(message: om, replyAll: false))
            case .replyAll:
                setInitialBody(text: ReplyUtil.quotedMessageText(message: om, replyAll: true))
            case .forward:
                setBodyPotetionallyTakingOverAttachments()
            case .normal:
                if isDraftsOrOutbox {
                    setBodyPotetionallyTakingOverAttachments()
                }
                // do nothing.
            }
        }

        mutating private func setInitialBody(text: String) {
            if text.isEmpty {
                bodyPlaintext = ""
            } else {
                bodyPlaintext = text
            }
        }

        mutating private func setInitialBody(text: NSAttributedString) {
            bodyHtml = text
        }

        /// Is sutable for isDraftsOrOutbox || composeMode == .forward only.
        mutating private func setBodyPotetionallyTakingOverAttachments() {
            guard let msg = cloneMessage else {
                Log.shared.errorAndCrash("Inconsitant state")
                return
            }

            guard isDraftsOrOutbox || composeMode == .forward else {
                Log.shared.errorAndCrash("Unsupported mode or message")
                return
            }
            if let html = msg.longMessageFormatted {
                // We have HTML content. Parse it taking inlined attachments into account.
                let parserDelegate = InitDataHtmlToAttributedTextSaxParserAttachmentDelegate(
                    inlinedAttachments: inlinedAttachments)
                let attributedString = html.htmlToAttributedString(attachmentDelegate: parserDelegate)
                var result = attributedString
                if composeMode == .forward {
                    // forwarded messges must have a cite header ("yxz wrote on ...")
                    result = ReplyUtil.citedMessageText(textToCite: attributedString,
                                                        fromMessage: msg)
                }
                setInitialBody(text: result)
            } else {
                // No HTML available.
                var result = msg.longMessage ?? ""
                if composeMode == .forward {
                    // forwarded messges must have a cite header ("yxz wrote on ...")
                    result = ReplyUtil.citedMessageText(textToCite: msg.longMessage ?? "",
                                                        fromMessage: msg)
                }
                setInitialBody(text: result)
            }
        }
    }
}

// MARK: - HtmlToAttributedTextSaxParserAttachmentDelegate

class InitDataHtmlToAttributedTextSaxParserAttachmentDelegate: HtmlToAttributedTextSaxParserAttachmentDelegate {
    let inlinedAttachments: [Attachment]

    init(inlinedAttachments: [Attachment]) {
        self.inlinedAttachments = inlinedAttachments
    }
    func imageAttachment(src: String?, alt: String?) -> Attachment? {
        for attachment in inlinedAttachments {
            if attachment.contentID == src?.extractCid() {
                // The attachment is inlined.
                assertImage(inAttachment: attachment)
                return attachment
            }
        }
        return nil
    }

    private func assertImage(inAttachment attachment: Attachment) {
        // Assure the image is set.
        if attachment.image == nil {
            guard let safeData = attachment.data else {
                Log.shared.errorAndCrash("No data")
                return
            }
            attachment.image = UIImage(data: safeData)
        }
    }
}
