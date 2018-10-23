//
//  ComposeUtil.swift
//  pEp
//
//  Created by Andreas Buff on 18.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

/// Utils for composing a message. Helps finding out values depending on the original message
/// (the correct recipients, cancle actions ...).
struct ComposeUtil {

    enum ComposeMode {
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
                result = om.to
            } else if om.parent.folderType != .sent, let omFrom = om.from {
                result = [omFrom]
            }
        case .replyAll:
            if om.parent.folderType == .sent || om.parent.folderType == .drafts  {
                result = om.to
            } else if om.parent.folderType != .sent, let omFrom = om.from {
                guard let me = initialFrom(composeMode: composeMode, originalMessage: om) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No from")
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
                result = om.to
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
                result = om.cc
            } else {
                guard let me = initialFrom(composeMode: composeMode, originalMessage: om) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No from")
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
                result = om.cc
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
                result = om.bcc
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
            return Account.defaultAccount()?.user  //IOS-1369: bug: default only in unified inbox (?)
        }
    }

    // MARK: - Attachments

     /// - Returns: Noninlined attachments appropriate for the given compose mode
    static func initialNonInlinedAttachments(composeMode: ComposeMode,
                                             originalMessage om: Message?) -> [Attachment] {
        guard shouldTakeOverAttachments(composeMode: composeMode, originalMessage: om ) else {
            return []
        }
        guard let om = om else {
            // No om, no initial attachments
            return []
        }
        let nonInlinedAttachments = om.viewableAttachments()
            .filter { $0.contentDisposition == .attachment }
        return nonInlinedAttachments
    }

    /// Computes whether or not attachments must be taken over in current compose mode
    ///
    /// - Returns: true if we must take over attachments from the original message, false otherwize
    static private func shouldTakeOverAttachments(composeMode: ComposeMode,
                                                  originalMessage om: Message?) -> Bool {
        var isInDraftsOrOutbox = false
        if let om = om {
            isInDraftsOrOutbox = om.isInDraftsOrOutbox //IOS-1369: HERE: init attachments
        }
        return composeMode == .forward || isInDraftsOrOutbox
    }

    // MARK: - Message to send

    static public func messageToSend(withDataFrom state: ComposeViewModelState) -> Message? {
        guard let from = state.from,
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
        message.to = state.toRecipients
        message.cc = state.ccRecipients
        message.bcc = state.bccRecipients
        message.shortMessage = state.subject
        message.longMessage = state.bodyPlaintext
        message.longMessageFormatted = state.bodyHtml
        message.attachments = state.inlinedAttachments + state.nonInlinedAttachments
        message.pEpProtected = state.pEpProtection

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

        message.setOriginalRatingHeader(rating: state.rating) // This should be moved. Algo did change. Currently we set it here and remove it when sending. We should set it where it should be set instead. Probalby in append OP
        return message
    }
}
