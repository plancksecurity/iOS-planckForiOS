//
//  ComposeUtil.swift
//  pEp
//
//  Created by Andreas Buff on 18.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

/// Utils for composing a message. Helps finding out values depending on the original message
/// (the correct recipients, cancle actions ...).
struct ComposeUtil {
    enum ComposeMode: CaseIterable {
        case normal
        case replyFrom
        case replyAll
        case forward
    }

    // MARK: - Recipients

    static func initialTos(composeMode: ComposeMode, originalMessage om: Message) -> [Identity] {
        var result = [Identity]()
        switch composeMode {
        case .replyFrom:
            if om.parent.folderType == .sent || om.parent.folderType == .drafts {
                result = om.to.allObjects
            } else if om.parent.folderType != .sent, let omFrom = om.from {
                result = [omFrom]
            }
        case .replyAll:
            if om.parent.folderType == .sent || om.parent.folderType == .drafts  {
                result = om.to.allObjects
            } else if om.parent.folderType != .sent, let omFrom = om.from {
                guard let me = initialFrom(composeMode: composeMode, originalMessage: om) else {
                    Log.shared.errorAndCrash("No from")
                    return result
                }
                let origTos = om.to
                let originalTosWithoutMe = origTos.filter { $0 != me}
                result = originalTosWithoutMe + [omFrom]
            }
        case .normal:
            if om.parent.folderType == .sent ||
                om.parent.folderType == .drafts ||
                om.parent.folderType == .outbox  {
                result = om.to.allObjects
            }
        case .forward:
            break
        }
        return result
    }

    static func initialCcs(composeMode: ComposeMode, originalMessage om: Message) -> [Identity] {
        var result = [Identity]()
        switch composeMode {
        case .replyAll:
            if om.parent.folderType == .sent || om.parent.folderType == .drafts {
                result = om.cc.allObjects
            } else {
                guard let me = initialFrom(composeMode: composeMode, originalMessage: om) else {
                    Log.shared.errorAndCrash("No from")
                    return result
                }
                let origCcs = om.cc
                result = origCcs.filter { $0 != me}
            }
        case .replyFrom, .forward:
            break
        case .normal:
            if om.parent.folderType == .sent ||
                om.parent.folderType == .drafts ||
                om.parent.folderType == .outbox  {
                result = om.cc.allObjects
            }
        }
        return result
    }

    static func initialBccs(composeMode: ComposeMode, originalMessage om: Message) -> [Identity] {
        var result = [Identity]()
        switch composeMode {
        case .normal:
            if om.parent.folderType == .sent ||
                om.parent.folderType == .drafts ||
                om.parent.folderType == .outbox {
                result = om.bcc.allObjects
            }
        case .replyFrom, .forward, .replyAll:
            break
        }
        return result
    }

    static func initialFrom(composeMode: ComposeMode, originalMessage om: Message?) -> Identity? {
        switch composeMode {
        case .replyFrom, .replyAll, .forward:
            return om?.parent.account.user
        case .normal:
            if let om = om,
               om.parent.folderType == .sent ||
                om.parent.folderType == .drafts ||
                om.parent.folderType == .outbox  {
                return om.from
            }
            return Account.defaultAccount()?.user
        }
    }

    // MARK: - Attachments

    /// - Returns: attachments appropriate for the given compose mode
    static func initialAttachments(composeMode: ComposeMode,
                                   contentDisposition: Attachment.ContentDispositionType,
                                   originalMessage om: Message?) -> [Attachment] {
        guard shouldTakeOverAttachments(composeMode: composeMode, originalMessage: om ) else {
            return []
        }
        guard let om = om else {
            // No om, no initial attachments
            return []
        }
        let viewAbleAttachments = om.viewableAttachments()
            .filter { $0.contentDisposition == contentDisposition }

        let privateSession = Session()
        let result = viewAbleAttachments.map { $0.clone(for: privateSession) }
        return result
    }

    /// Computes whether or not attachments must be taken over in current compose mode
    ///
    /// - Returns: true if we must take over attachments from the original message, false otherwize
    static private func shouldTakeOverAttachments(composeMode: ComposeMode,
                                                  originalMessage om: Message?) -> Bool {
        var isInDraftsOrOutbox = false
        if let om = om {
            isInDraftsOrOutbox = om.isInDraftsOrOutbox
        }
        return composeMode == .forward || isInDraftsOrOutbox
    }

    /// Creates a message from the given ComposeView State
    ///
    /// - note: MUST NOT be used on the main Session. For the maion Session, use
    ///         messageToSend(withDataFrom:) instead.
    ///
    /// - Parameter state: state to get data from
    /// - Parameter recipientsOnly: the returned message holds recipients only (no attachments, body, ...)
    /// - Returns: new message with data from given state
    static public func messageToSend(withDataFrom state: ComposeViewModel.ComposeViewModelState,
                                     recipientsOnly: Bool = false) -> Message? {
        guard
            let from = state.from,
            let session = state.from?.session,
            let account = Account.by(address: from.address, in: session)?.safeForSession(session),
            let outbox = Folder.by(account: account, folderType: .outbox)?.safeForSession(session)
        else {
            Log.shared.errorAndCrash("Invalid state")
            return nil
        }

        let message = Message.newOutgoingMessage(session: session)
        message.parent = outbox
        message.from = from
        message.replaceTo(with: state.toRecipients)
        message.replaceCc(with: state.ccRecipients)
        message.replaceBcc(with: state.bccRecipients)
        guard !recipientsOnly else {
            return message
        }
        let inlinedAttachments = Attachment.makeSafe(state.inlinedAttachments, forSession: session)
        let nonInlinedAttachments = Attachment.makeSafe(state.nonInlinedAttachments, forSession: session)
        //!!!: DIRTY ALARM!
        //!!!: ADAM:
        //BUFF: !!!

        //Replace white font with black font.
        let mutableBodyText = NSMutableAttributedString(attributedString: state.bodyText)
        var attributes = state.bodyText.attributes(at: 0, effectiveRange: nil)
        attributes[.foregroundColor] = UIColor.black
        mutableBodyText.setAttributes(attributes, range: state.bodyText.wholeRange())

        let body = mutableBodyText.toHtml(inlinedAttachments: inlinedAttachments) //!!!: ADAM: Bad! method called toHtml returns plaintext
        let bodyPlainText = body.plainText
        let bodyHtml = body.html ?? ""
        message.shortMessage = state.subject
        message.longMessage = bodyPlainText
        message.longMessageFormatted = !bodyHtml.isEmpty ? bodyHtml : nil
        message.replaceAttachments(with: inlinedAttachments + nonInlinedAttachments)
        message.pEpProtected = state.pEpProtection
        if !state.pEpProtection {
            let unprotectedRating = Rating.unencrypted
            message.setOriginalRatingHeader(rating: unprotectedRating)
            message.pEpRatingInt = unprotectedRating.toInt()
        } else {
            message.setOriginalRatingHeader(rating: state.rating)
            message.pEpRatingInt = state.rating.toInt()
        }

        message.imapFlags.seen = imapSeenState(forMessageToSend: message)

        return message
    }

    static private func imapSeenState(forMessageToSend msg: Message) -> Bool {
        if msg.parent.folderType == .outbox || msg.parent.folderType == .sent {
            return true
        } else {
            return false
        }
    }
}
