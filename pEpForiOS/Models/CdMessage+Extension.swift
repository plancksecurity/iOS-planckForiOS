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

    public static func createWithDefaults(
        messageID: String, uid: Int, parent: CdFolder? = nil,
        in context: NSManagedObjectContext = Record.Context.default) -> CdMessage {
        let imap = CdImapFields.create(context: context)
        var dict: [String: Any] = ["uuid": messageID, "uid": uid, "imap": imap]
        if let pf = parent {
            dict["parent"] = pf
        }
        return create(attributes: dict)
    }

    static func existingMessagesPredicate() -> NSPredicate {
        let pBody = NSPredicate.init(format: "bodyFetched = true")
        let pNotDeleted = NSPredicate.init(format: "imap.flagDeleted = false")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [pBody, pNotDeleted])
    }

    public static func basicMessagePredicate() -> NSPredicate {
        let predicateDecrypted = NSPredicate.init(format: "pEpRating != %d", PEPUtil.pEpRatingNone)
        let predicates: [NSPredicate] = [existingMessagesPredicate(), predicateDecrypted]
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    public static func unencryptedMessagesPredicate() -> NSPredicate {
        let predicateDecrypted = NSPredicate.init(format: "pEpRating == %d", PEPUtil.pEpRatingNone)
        let predicates: [NSPredicate] = [existingMessagesPredicate(), predicateDecrypted]
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    public static func messagesWithChangedFlagsPredicate(folder: CdFolder? = nil) -> NSPredicate {
        var pFolder = NSPredicate(value: true)
        if let f = folder {
            pFolder = NSPredicate(format: "parent = %@", f)
        }
        let pFlags = NSPredicate(format: "imap.flagsCurrent != imap.flagsFromServer")
        let pUid = NSPredicate(format: "uid != 0")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [pUid, pFolder, pFlags])
    }

    public static func countBy(predicate: NSPredicate) -> Int {
        let objs = all(predicate: predicate)
        return objs?.count ?? 0
    }

    public static func by(uid: Int) -> CdMessage? {
        return first(attribute: "uid", value: uid)
    }

    /**
     The original (`addToTo`) crashes
     */
    public func addTo(cdIdentity: CdIdentity) {
        to = NSOrderedSet.adding(elements: [cdIdentity], toSet: to)
    }

    /**
     The original (`addToCc`) crashes
     */
    public func addCc(cdIdentity: CdIdentity) {
        cc = NSOrderedSet.adding(elements: [cdIdentity], toSet: cc)
    }

    /**
     The original (`addToBcc`) crashes
     */
    public func addBcc(cdIdentity: CdIdentity) {
        bcc = NSOrderedSet.adding(elements: [cdIdentity], toSet: bcc)
    }

    /**
     The original (`addToReferences`) crashes
     */
    public func addReference(cdMessageReference: CdMessageReference) {
        references = NSOrderedSet.adding(elements: [cdMessageReference], toSet: references)
    }

    static func insertAttachment(
        contentType: String?, filename: String?, data: Data) -> CdAttachment {
        let attachment = CdAttachment.create(attributes: ["data": data, "size": data.count])
        attachment.mimeType = contentType
        attachment.fileName = filename
        return attachment
    }
}
