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

    static func existingMessagesPredicate() -> NSPredicate {
        let pBody = NSPredicate.init(format: "bodyFetched = true")
        let pNotDeleted = NSPredicate(format: "imap.localFlags.flagDeleted = false")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [pBody, pNotDeleted])
    }

    public static func basicMessagePredicate() -> NSPredicate {
        let predicateDecrypted = NSPredicate(format: "pEpRating != %d", PEPUtil.pEpRatingNone)
        let predicates = [existingMessagesPredicate(), predicateDecrypted]
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    public static func unknownToPepMessagesPredicate() -> NSPredicate {
        let predicateDecrypted = NSPredicate(format: "pEpRating == %d", PEPUtil.pEpRatingNone)
        let predicateIsFromServer = NSPredicate(format: "uid > 0")
        let predicates = [existingMessagesPredicate(), predicateDecrypted, predicateIsFromServer]
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

    static func insertAttachment( //IOS-872: CID unaware
        contentType: String?, filename: String?,contentID: String?, data: Data) -> CdAttachment {
        let attachment = CdAttachment.create()
        attachment.data = data
        attachment.length = Int64(data.count)
        attachment.mimeType = contentType?.lowercased()
        // We mimic the Engines behaviour: cid has higher prio. 
        if let cid = contentID {
            // We never saw the IMAP layer returning a CID that is prefixed with `cid:`,
            // but you never know ...
            attachment.fileName = cid.contains(find: "cid:") ? cid : "cid:" + cid
        } else {
            attachment.fileName = filename
        }
        return attachment
    }
}
