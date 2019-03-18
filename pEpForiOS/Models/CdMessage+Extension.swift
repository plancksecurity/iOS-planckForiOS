//
//  CdMessage+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

extension CdMessage {

    public func allRecipienst() -> NSOrderedSet {
        let recipients: NSMutableOrderedSet = []
        recipients.addObjects(from: (to?.array)!)
        recipients.addObjects(from: (cc?.array)!)
        recipients.addObjects(from: (bcc?.array)!)
        return recipients
    }

    /**
     - Returns: Some string that identifies a mail, useful for logging.
     */
    public func logString() -> String {
        let string = NSMutableString()

        let append = {
            if string.length > 1 {
                string.append(", ")
            }
        }

        string.append("(")
        if let msgID = messageID {
            append()
            string.append("messageID: \(msgID)")
        }
        string.append(" UID: \(uid)")
        if let oDate = sent {
            append()
            string.append("date: \(oDate)")
        }
        string.append(")")
        return string as String
    }

    public static func create(messageID: String, uid: Int,
                              parent: CdFolder? = nil) -> CdMessage {
        let msg = CdMessage.create()
        msg.uuid = messageID
        msg.uid = Int32(uid)
        msg.parent = parent
        msg.imap = CdImapFields.create()
        return msg
    }

    @discardableResult public static func create(withContentOf msg: Message) -> CdMessage? {  //!!!: MUST NOT, be in app!?
        guard
            let cdParentFolder = msg.parent.cdFolder(),
            let from = msg.from?.cdIdentity() else {
            Log.shared.errorAndCrash(component: #function, errorString: "No parent")
            return nil
        }
        let createe = CdMessage.create()
        createe.uid = Int32(msg.uid)
        createe.uuid = msg.uuid
        createe.parent = cdParentFolder

        createe.imap = CdImapFields.create()

        createe.imap?.localFlags?.flagAnswered = msg.imapFlags.answered
        createe.imap?.localFlags?.flagDeleted = msg.imapFlags.deleted
        createe.imap?.localFlags?.flagDraft = msg.imapFlags.draft
        createe.imap?.localFlags?.flagFlagged = msg.imapFlags.flagged
        createe.imap?.localFlags?.flagRecent = msg.imapFlags.recent
        createe.imap?.localFlags?.flagSeen = msg.imapFlags.seen

        createe.shortMessage = msg.shortMessage
        createe.longMessage = msg.longMessage
        createe.longMessageFormatted = msg.longMessageFormatted

        let cdAttachments = msg.attachments.map { CdAttachment.create(attachment: $0) }
        createe.attachments = NSOrderedSet(array: cdAttachments)

        createe.sent = msg.sent
        createe.from = from

        let cdTos = msg.to.compactMap { $0.cdIdentity() }
        createe.to = NSOrderedSet(array: cdTos)

        let cdCcs = msg.cc.compactMap { $0.cdIdentity() }
        createe.cc = NSOrderedSet(array: cdCcs)

        let cdBccs = msg.bcc.compactMap { $0.cdIdentity() }
        createe.bcc = NSOrderedSet(array: cdBccs)

        createe.pEpRating = Int16(msg.pEpRating().rawValue)

        return createe
    }

    public static func countBy(predicate: NSPredicate) -> Int {
        let objs = all(predicate: predicate)
        return objs?.count ?? 0
    }

    static func insertAttachment(contentType: String?,
                                 filename: String?,
                                 contentID: String?,
                                 data: Data,
                                 contentDispositionRawValue: Int16) -> CdAttachment {
        let attachment = CdAttachment.create()
        attachment.data = data
        attachment.length = Int64(data.count)
        attachment.mimeType = contentType?.lowercased()
        // We mimic the Engines behaviour to set filename *or* CID in field `filename`. CID has higher prio.
        if let cid = contentID {
            attachment.fileName = Attachment.contentIdUrlScheme + "://" + cid
        } else {
            attachment.fileName = filename
        }
        attachment.contentDispositionTypeRawValue = contentDispositionRawValue
        return attachment
    }
}
