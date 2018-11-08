//
//  ComposeViewModel+InitData.swift
//  pEp
//
//  Created by Andreas Buff on 15.10.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

// MARK: - InitData

extension ComposeViewModel {
    /// Wraps properties used for initial setup
    struct InitData {
        /// Recipient to set as "To:".
        /// Is ignored if a originalMessage is set.
        public let prefilledTo: Identity?
        /// Original message to compute content and recipients from (e.g. a message we reply to).
        public let originalMessage: Message?

        public let composeMode: ComposeUtil.ComposeMode

        /// Whether or not the original message is in Drafts or Outbox
        var isDraftsOrOutbox: Bool {
            return isDrafts || isOutbox
        }

        /// Whether or not the original message is in Drafts folder
        var isDrafts: Bool {
            if let om = originalMessage {
                return om.parent.folderType == .drafts
            }
            return false
        }

        /// Whether or not the original message is in Outbox
        var isOutbox: Bool {
            if let om = originalMessage {
                return om.parent.folderType == .outbox
            }
            return false
        }

        var pEpProtection: Bool {
            return originalMessage?.pEpProtected ?? true
        }

        var from: Identity? {
            return ComposeUtil.initialFrom(composeMode: composeMode,
                                           originalMessage: originalMessage)
        }

        var toRecipients: [Identity] {
            if let om = originalMessage {
                return ComposeUtil.initialTos(composeMode: composeMode, originalMessage: om)
            } else if let presetTo = prefilledTo {
                return [presetTo]
            }
            return []
        }

        var ccRecipients: [Identity] {
            guard let om = originalMessage else {
                return []
            }
            return ComposeUtil.initialCcs(composeMode: composeMode, originalMessage: om)
        }

        var bccRecipients: [Identity] {
            guard let om = originalMessage else {
                return []
            }
            return ComposeUtil.initialBccs(composeMode: composeMode, originalMessage: om)
        }

        var subject = " "

        var bodyPlaintext = ""
        var bodyHtml: NSAttributedString?

        public var nonInlinedAttachments: [Attachment] {
            return ComposeUtil.initialAttachments(composeMode: composeMode,
                                                  contentDisposition: .attachment,
                                                  originalMessage: originalMessage)
        }

        public var inlinedAttachments: [Attachment] {
            return ComposeUtil.initialAttachments(composeMode: composeMode,
                                                  contentDisposition: .inline,
                                                  originalMessage: originalMessage)
        }

        init(withPrefilledToRecipient prefilledTo: Identity? = nil,
             orForOriginalMessage om: Message? = nil,
             composeMode: ComposeUtil.ComposeMode? = nil) {
            self.composeMode = composeMode ?? ComposeUtil.ComposeMode.normal
            self.originalMessage = om
            self.prefilledTo = om == nil ? prefilledTo : nil
            setupInitialSubject()
            setupInitialBody()
        }

        mutating private func setupInitialSubject() {
            guard let om = originalMessage else {
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
            guard let om = originalMessage else {
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
            guard let msg = originalMessage else {
                Log.shared.errorAndCrash(component: #function, errorString: "Inconsitant state")
                return
            }

            guard isDraftsOrOutbox || composeMode == .forward else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "Unsupported mode or message")
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
                Log.shared.errorAndCrash(component: #function, errorString: "No data")
                return
            }
            attachment.image = UIImage(data: safeData)
        }
    }
}
