//
//  CdMessage+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 17/10/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension CdMessage {
    /**
     - Returns: A `CWFlags object` for the given `NSNumber`
     */
    static open func pantomimeFlagsFromNumber(_ flags: Int16) -> CWFlags {
        if let fl = PantomimeFlag.init(rawValue: UInt(flags)) {
            return CWFlags.init(flags: fl)
        }
        Log.error(component: 
            "Message", errorString:
            "Could not convert \(flags) to PantomimeFlag")
        return CWFlags.init()
    }

    /**
     - Returns: The current flags as String, like "\Deleted \Answered"
     */
    static func flagsStringFromNumber(_ flags: Int16) -> String {
        return pantomimeFlagsFromNumber(flags).asString()
    }

    func allRecipienst() -> NSOrderedSet {
        let recipients: NSMutableOrderedSet = []
        recipients.addObjects(from: (to?.array)!)
        recipients.addObjects(from: (cc?.array)!)
        recipients.addObjects(from: (bcc?.array)!)
        return recipients
    }

    /**
     - Returns: Some string that identifies a mail, useful for logging.
     */
    func logString() -> String {
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
        string.append("\(uid)")
        if let oDate = received {
            append()
            string.append("date: \(oDate)")
        }
        string.append(")")
        return string as String
    }

    /**
     - Returns: `flags` as `CWFlags`
     */
    public func pantomimeFlags() -> CWFlags {
        return CdMessage.pantomimeFlagsFromNumber(imap!.flagsCurrent)
    }

    /**
     - Returns: `flagsFromServer` as `CWFlags`
     */
    public func pantomimeFlagsFromServer() -> CWFlags {
        return CdMessage.pantomimeFlagsFromNumber(imap!.flagsFromServer)
    }

    public static func create(messageID: String, uid: Int) -> MessageModel.CdMessage {
        return MessageModel.CdMessage.create(with: ["uuid": messageID, "uid": uid])
    }

    static func existingMessagesPredicate() -> NSPredicate {
        let pBody = NSPredicate.init(format: "bodyFetched = true")
        let pNotDeleted = NSPredicate.init(format: "imapFlags.flagDeleted = false")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [pBody, pNotDeleted])
    }

    public static func basicMessagePredicate() -> NSPredicate {
        let predicateDecrypted = NSPredicate.init(format: "pEpRating != nil")
        let predicates: [NSPredicate] = [existingMessagesPredicate(), predicateDecrypted]
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    public static func unencryptedMessagesPredicate() -> NSPredicate {
        let predicateDecrypted = NSPredicate.init(format: "pEpRating == nil")
        let predicates: [NSPredicate] = [existingMessagesPredicate(), predicateDecrypted]
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }

    public static func messagesWithChangedFlagsPredicate(folder: CdFolder? = nil) -> NSPredicate {
        var pFolder = NSPredicate(value: true)
        if let f = folder {
            pFolder = NSPredicate(format: "parent = %@", f)
        }
        let pFlags = NSPredicate(format: "imap.flagsCurrent != imap.flagsFromServer")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [pFolder, pFlags])
    }

    public static func countBy(predicate: NSPredicate) -> Int {
        let objs = MessageModel.CdMessage.all(with: predicate)
        return objs?.count ?? 0
    }

    public static func by(uid: Int) -> MessageModel.CdMessage? {
        return MessageModel.CdMessage.first(with: "uid", value: uid)
    }

    var messageID: String? {
        return uuid
    }

    /**
     The original (`addToTo`) crashes
     */
    public func addTo(identity: CdIdentity) {
        let key = "to"
        willChangeValue(forKey: key)
        to = NSOrderedSet.adding(elements: [identity], toSet: to)
        didChangeValue(forKey: key)
    }

    /**
     The original (`addToCc`) crashes
     */
    public func addCc(identity: CdIdentity) {
        let key = "cc"
        willChangeValue(forKey: key)
        cc = NSOrderedSet.adding(elements: [identity], toSet: cc)
        didChangeValue(forKey: key)
    }

    /**
     The original (`addToBcc`) crashes
     */
    public func addBcc(identity: CdIdentity) {
        let key = "bcc"
        willChangeValue(forKey: key)
        bcc = NSOrderedSet.adding(elements: [identity], toSet: bcc)
        didChangeValue(forKey: key)
    }

    /**
     - Returns: A `CWFlags object` for the given `Int16`
     */
    static open func pantomimeFlags(flagsInt16: Int16) -> CWFlags {
        if let fl = PantomimeFlag(rawValue: UInt(flagsInt16)) {
            return CWFlags.init(flags: fl)
        }
        Log.error(component:
            "Message", errorString:
            "Could not convert \(flagsInt16) to PantomimeFlag")
        return CWFlags.init()
    }

    /**
     - Returns: The current flags as String, like "\Deleted \Answered"
     */
    static func flagsString(flagsInt16: Int16) -> String {
        return pantomimeFlags(flagsInt16: flagsInt16).asString()
    }

    /**
     - Returns: A tuple consisting of an IMAP command string for updating
     the flags for this message, and a dictionary suitable for using pantomime
     for the actual execution.
     - Note: The generated command will always simply overwrite the flags
     on the server with the local one. It will not figure out individual flags.
     */
    public func storeCommandForUpdate() -> (String, [AnyHashable: Any])? {
        guard let flags = imap?.flagsCurrent else {
            return nil
        }

        // Construct a very minimal pantomime dummy for the info dictionary
        let pantomimeMail = CWIMAPMessage.init()
        pantomimeMail.setUID(UInt(uid))

        var dict: [AnyHashable: Any] = [PantomimeMessagesKey:
            NSArray.init(object: pantomimeMail)]

        var result = "UID STORE \(uid) "
        let flagsString = MessageModel.CdMessage.flagsString(flagsInt16: flags)
        result += "FLAGS.SILENT (\(flagsString))"

        dict[PantomimeFlagsKey] = MessageModel.CdMessage.pantomimeFlags(flagsInt16: flags)
        return (command: result, dictionary: dict)
    }

    /**
     Call this after any update to the flags. Should be automated with `didSet`.
     */
    public func updateFlags() {
        let theImap = imap ?? CdImapFields.create()
        imap = theImap
        let cwFlags = CWFlags.init()
        let allFlags: [(Bool, PantomimeFlag)] = [
            (theImap.flagSeen, PantomimeFlag.seen),
            (theImap.flagDraft, PantomimeFlag.draft),
            (theImap.flagRecent, PantomimeFlag.recent),
            (theImap.flagDeleted, PantomimeFlag.deleted),
            (theImap.flagAnswered, PantomimeFlag.answered),
            (theImap.flagFlagged, PantomimeFlag.flagged)]
        for (p, f) in allFlags {
            if p {
                cwFlags.add(f)
            }
        }
        theImap.flagsCurrent = cwFlags.rawFlagsAsShort()
    }

    /**
     Convert the `Message` into an `CWIMAPMessage`, belonging to the given folder.
     - Note: This does not handle attachments and many other fields.
     *It's just for quickly interfacing with Pantomime.*
     */
    func pantomimeMessage(folder: CWIMAPFolder) -> CWIMAPMessage {
        let msg = CWIMAPMessage.init()

        if let date = received {
            msg.setReceivedDate(date as Date)
        }

        if let sub = shortMessage {
            msg.setSubject(sub)
        }

        if let str = messageID {
            msg.setMessageID(str)
        }

        msg.setUID(UInt(uid))

        if let msn = imap?.messageNumber {
            msg.setMessageNumber(UInt(msn))
        }

        if let boundary = imap?.mimeBoundary {
            msg.setBoundary(boundary.data(using: String.Encoding.ascii))
        }

        if let contact = from {
            msg.setFrom(internetAddressFromContact(contact))
        }

        var recipients: [CWInternetAddress] = []
        collectContacts(cc, asPantomimeReceiverType: .ccRecipient,
                        intoTargetArray: &recipients)
        collectContacts(bcc, asPantomimeReceiverType: .bccRecipient,
                        intoTargetArray: &recipients)
        collectContacts(to, asPantomimeReceiverType: .toRecipient,
                        intoTargetArray: &recipients)
        msg.setRecipients(recipients)

        var refs: [String] = []
        if let theRefs = references {
            for ref in theRefs {
                if let refString: String = (ref as! CdMessageReference).reference {
                    refs.append(refString)
                }
            }
        }
        msg.setReferences(refs)

        if let ct = imap?.contentType {
            msg.setContentType(ct)
        }

        msg.setFolder(folder)

        // Avoid roundtrips to the server, just set the flags directly.
        if let flags = imap?.flagsCurrent {
            msg.flags().replace(with: CWFlags.init(int: Int(flags)))
        }

        return msg
    }

    func internetAddressFromContact(_ contact: CdIdentity) -> CWInternetAddress {
        return CWInternetAddress.init(personal: contact.userName, address: contact.address)
    }

    func collectContacts(_ contacts: NSOrderedSet?,
                         asPantomimeReceiverType receiverType: PantomimeRecipientType,
                         intoTargetArray target: inout [CWInternetAddress]) {
        guard let cs = contacts else {
            return
        }
        for obj in cs {
            if let theContact = obj as? CdIdentity {
                let addr = internetAddressFromContact(theContact)
                addr.setType(receiverType)
                target.append(addr)
            }
        }
    }

    /**
     Updates all properties from the given `PEPMail`.
     Used after a mail has been decrypted.
     That means that for now, recipients are not overwritten, because they don't
     change after decrypt (until the engine handles the communication layer too).
     What can change is body text, subject, attachments.
     TODO: Take care of optional fields (`kPepOptFields`)!
     */
    public func update(pEpMail: PEPMail, pepColorRating: PEP_rating? = nil) {
        if let color = pepColorRating {
            pEpRating = Int16(color.rawValue)
        } else {
            pEpRating = Int16(PEP_rating_undefined.rawValue)
        }
        shortMessage = pEpMail[kPepShortMessage] as? String
        longMessage = pEpMail[kPepLongMessage] as? String
        longMessageFormatted = pEpMail[kPepLongMessageFormatted] as? String

        // Remove all existing attachments. These should cascade.

        var attachments = [CdAttachment]()
        if let attachmentDicts = pEpMail[kPepAttachments] as? NSArray {
            for atDict in attachmentDicts {
                guard let at = atDict as? NSDictionary else {
                    continue
                }
                guard let data = at[kPepMimeData] as? Data else {
                    continue
                }
                var attachData: [String: Any] = ["data": data, "size": data.count]
                if let mt = at[kPepMimeType] {
                    attachData["mimeType"] = mt
                }
                if let fn = at[kPepMimeFilename] {
                    attachData["fileName"] = fn
                }

                let attach = CdAttachment.create(with: attachData)
                attachments.append(attach)
            }
        }
        self.attachments = NSOrderedSet(array: attachments)
    }
}
