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

    public static func basicMessagePredicate() -> NSPredicate {
        let predicates = [CdMessage.PredicateFactory.existingMessages(),
                          CdMessage.PredicateFactory.decrypted()]
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    public static func unknownToPepMessagesPredicate() -> NSPredicate {
        var reDecryptionRatings = PEP_rating.retryDecriptionRatings.map {
            return $0.rawValue
        }
        reDecryptionRatings.append(Int32(PEPUtil.pEpRatingNone))

        let predicateDecrypted = NSPredicate(format: "pEpRating in %@",
                                             reDecryptionRatings)
        let predicateIsFromServer = NSPredicate(format: "uid > 0")
        let predicates = [CdMessage.PredicateFactory.existingMessages(),
                          predicateDecrypted,
                          predicateIsFromServer]
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    /**
     - Note: \Recent is never taken into consideration, since it always is set from the server,
     but never overridden in the client.
     - Returns: A predicate that will search for all messages in a given folder whose flags
     should be synced back to the server. That is, messages with locally changed flags.
     */
    public static func messagesWithChangedFlagsPredicate(folder: CdFolder? = nil) -> NSPredicate {
        var predicates = [NSPredicate]()

        if let f = folder {
            predicates.append(NSPredicate(format: "parent = %@", f))
        }

        let pFlags = NSPredicate(format:
            "(imap.localFlags.flagAnswered != imap.serverFlags.flagAnswered) OR " +
            "(imap.localFlags.flagDraft != imap.serverFlags.flagDraft) OR " +
            "(imap.localFlags.flagFlagged != imap.serverFlags.flagFlagged) OR " +
            "(imap.localFlags.flagSeen != imap.serverFlags.flagSeen) OR " +
            "(imap.localFlags.flagDeleted != imap.serverFlags.flagDeleted)")
        predicates.append(pFlags)

        let pUid = NSPredicate(format: "uid != 0")
        predicates.append(pUid)
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
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
