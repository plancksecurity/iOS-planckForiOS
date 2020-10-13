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
        /// Recipients to set as "To:".
        /// Is ignored if a originalMessage is set.
        public let prefilledTos: [Identity]?

        /// Recipients to set as "CC:".
        /// are ignored if a originalMessage is set.
        public let prefilledCCs: [Identity]?

        /// Recipients to set as "BCC:".
        /// are ignored if a originalMessage is set.
        public let prefilledBCCs: [Identity]?

        /// Sender to set as "From:".
        /// If null it will be calculated from compose mode or set as default user.
        public let prefilledFrom: Identity?

        /// Original message to compute content and recipients from (e.g. a message we reply to).
        private var _originalMessage: Message? = nil
        public var originalMessage: Message? {
            get {
                guard !(_originalMessage?.isDeleted ?? true) else {
                    // Makes sure we do not access properties af a messages that has been deleted
                    // in the DB.
                    return nil
                }
                return _originalMessage
            }
            set {
                _originalMessage = newValue
            }
        }

        public let composeMode: ComposeUtil.ComposeMode

        /// Whether or not the original message is in Drafts folder
        public var isDrafts: Bool {
            if let om = originalMessage {
                return om.parent.folderType == .drafts
            }
            return false
        }

        /// Whether or not the original message is in Outbox
        public var isOutbox: Bool {
            if let om = originalMessage {
                return om.parent.folderType == .outbox
            }
            return false
        }

        public var pEpProtection: Bool {
            return originalMessage?.pEpProtected ?? true
        }

        public var from: Identity? {
            return prefilledFrom ?? ComposeUtil.initialFrom(composeMode: composeMode,
                                           originalMessage: originalMessage)
        }

        public var toRecipients: [Identity] {
            if let om = originalMessage {
                return ComposeUtil.initialTos(composeMode: composeMode, originalMessage: om)
            } else if let presetTos = prefilledTos {
                return presetTos
            }
            return []
        }

        public var ccRecipients: [Identity] {
            if let prefilledCCs = prefilledCCs {
                return prefilledCCs
            }
            guard let om = originalMessage else {
                return []
            }
            return ComposeUtil.initialCcs(composeMode: composeMode, originalMessage: om)
        }

        public var bccRecipients: [Identity] {
            if let prefilledBCCs = prefilledBCCs {
                return prefilledBCCs
            }
            guard let om = originalMessage else {
                return []
            }
            return ComposeUtil.initialBccs(composeMode: composeMode, originalMessage: om)
        }

        public var subject = " "

        public var bodyPlaintext = ""
        public var bodyHtml: NSAttributedString?

        public var nonInlinedAttachments = [Attachment]()
        public var inlinedAttachments = [Attachment]()

        init(prefilledTos: [Identity]? = nil,
             prefilledCCs: [Identity]? = nil,
             prefilledBCCs: [Identity]? = nil,
             composeMode: ComposeUtil.ComposeMode? = nil,
             orForOriginalMessage om: Message? = nil,
             prefilledFromSender prefilledFrom: Identity? = nil) {
            // We are cloning the message to get a clone off the attachments and the
            // longMessageFormatted updated with the CID:s of the cloned attachments.
            // We use it for settingus up and delete afterwards.
            let cloneMessage = om?.cloneWithZeroUID(session: Session.main)
            self.composeMode = composeMode ?? ComposeUtil.ComposeMode.normal
            if let prefilledTos = prefilledTos {
                self.prefilledTos = cloneMessage == nil ? prefilledTos : nil
            } else {
                self.prefilledTos = nil
            }
            self.prefilledCCs = prefilledCCs
            self.prefilledBCCs = prefilledBCCs
            self.prefilledFrom = prefilledFrom
            self.originalMessage = om
            self.inlinedAttachments = ComposeUtil.initialAttachments(composeMode: self.composeMode,
                                                                     contentDisposition: .inline,
                                                                     originalMessage: cloneMessage)
            self.nonInlinedAttachments = ComposeUtil.initialAttachments(composeMode: self.composeMode,
                                                                        contentDisposition: .attachment,
                                                                        originalMessage: cloneMessage)
            setupInitialSubject()
            setupInitialBody(from: cloneMessage)
            cloneMessage?.delete()
        }

        mutating private func setupInitialSubject() {
            guard let originalMessage = originalMessage else {
                // We have no original message. That's OK for compose mode .normal.
                return
            }
            switch composeMode {
            case .replyFrom,
                 .replyAll:
                subject = ReplyUtil.replySubject(message: originalMessage)
            case .forward:
                subject = ReplyUtil.forwardSubject(message: originalMessage)
            case .normal:
                if isDrafts {
                    subject = originalMessage.shortMessage ?? " "
                }
                // .normal is intentionally ignored here for other folder types
            }
        }

        mutating private func setupInitialBody(from message: Message?) {
            guard let message = message else {
                // We have no original message. That's OK for compose mode .normal.
                return
            }
            switch composeMode {
            case .replyFrom:
                setInitialBody(text: ReplyUtil.quotedMessageText(message: message, replyAll: false))
            case .replyAll:
                setInitialBody(text: ReplyUtil.quotedMessageText(message: message, replyAll: true))
            case .forward:
                setBodyPotetionallyTakingOverAttachments()
            case .normal:
                if isDrafts {
                    setBodyPotetionallyTakingOverAttachments()
                }
                // do nothing.
            }
        }

        mutating private func setInitialBody(text: NSAttributedString) {
            bodyHtml = text
        }

        /// Is sutable for isDrafts || composeMode == .forward only.
        mutating private func setBodyPotetionallyTakingOverAttachments() {
            guard let msg = originalMessage else {
                Log.shared.errorAndCrash("Inconsitant state")
                return
            }

            guard isDrafts || composeMode == .forward else {
                Log.shared.errorAndCrash("Unsupported mode or message")
                return
            }
            if let html = msg.longMessageFormatted {
                // Attachments must be (and are) on a private
                let attachmentSession = inlinedAttachments.first?.session
                // We have HTML content. Parse it taking inlined attachments into account.
                let parserDelegate = InitDataHtmlToAttributedTextSaxParserAttachmentDelegate(
                    inlinedAttachments: inlinedAttachments, session: attachmentSession)
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
                setInitialBody(text: NSAttributedString(string: result))
            }
        }
    }
}

// MARK: - HtmlToAttributedTextSaxParserAttachmentDelegate

private class InitDataHtmlToAttributedTextSaxParserAttachmentDelegate: HtmlToAttributedTextSaxParserAttachmentDelegate {
    private let inlinedAttachments: [Attachment]
    private let session: Session

    init(inlinedAttachments: [Attachment], session: Session? = Session.main) {
        self.inlinedAttachments = inlinedAttachments
        self.session = session ?? Session.main
    }
    func imageAttachment(src: String?, alt: String?) -> Attachment? {
        var result: Attachment? = nil
        session.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            for attachment in me.inlinedAttachments {
                if attachment.contentID == src?.extractCid() {
                    // The attachment is inlined.
                    me.assertImage(inAttachment: attachment)
                    result = attachment
                }
            }
        }
        return result
    }

    private func assertImage(inAttachment attachment: Attachment) {
        session.performAndWait {
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
}
