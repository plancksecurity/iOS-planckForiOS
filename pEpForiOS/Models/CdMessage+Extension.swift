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

    public static func create(messageID: String, uid: Int,
                              parent: CdFolder? = nil) -> CdMessage {
        let msg = CdMessage.create()
        msg.uuid = messageID
        msg.uid = Int32(uid)
        msg.parent = parent
        msg.imap = CdImapFields.createWithDefaults()
        return msg
    }

    public static func createWithDefaults(
        messageID: String, uid: Int, parent: CdFolder? = nil,
        in context: NSManagedObjectContext = Record.Context.default) -> CdMessage {
        let imap = CdImapFields.createWithDefaults(in: context)
        var dict: [String: Any] = ["uuid": messageID, "uid": uid, "imap": imap]
        if let pf = parent {
            dict["parent"] = pf
        }
        return create(with: dict)
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

	/* XXX: This code was in a file MessageModelCdMessage.swift with unpublic method of same name.
     * It is perhaps the one to be used instead of the code above.
	let predicateDecrypted = NSPredicate.init(format: "pepColorRating != nil")
        let predicateBody = NSPredicate.init(format: "bodyFetched = true")
        let predicateNotDeleted = NSPredicate.init(format: "flagDeleted = false")
        let predicates: [NSPredicate] = [predicateBody, predicateDecrypted,
                                         predicateNotDeleted]
        let predicate = NSCompoundPredicate.init(
            andPredicateWithSubpredicates: predicates)
        return predicate
	*/
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
        return NSCompoundPredicate(andPredicateWithSubpredicates: [pFolder, pFlags])
    }

    public static func countBy(predicate: NSPredicate) -> Int {
        let objs = all(with: predicate)
        return objs?.count ?? 0
    }

    public static func by(uid: Int) -> CdMessage? {
        return first(with: "uid", value: uid)
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
        let flagsString = CdMessage.flagsString(flagsInt16: flags)
        result += "FLAGS.SILENT (\(flagsString))"

        dict[PantomimeFlagsKey] = CdMessage.pantomimeFlags(flagsInt16: flags)
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
     TODO: Take care of optional fields (`kPepOptFields`)!
     */
    public func update(pEpMail: PEPMail, pepColorRating: PEP_rating? = nil) {
        if let color = pepColorRating {
            pEpRating = Int16(color.rawValue)
        }

        bodyFetched = true

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

        if let tos = pEpMail[kPepTo] as? [PEPContact] {
            for t in tos {
                print("\(t)")
            }
        }
    }

    /**
     Quickly inserts essential parts of a pantomime into the store. Needed for networking,
     where inserts should be quick and the persistent store should be up-to-date
     nevertheless (especially in terms of UIDs, messageNumbers etc.)
     - Returns: A tuple of the optional message just created or updated, and a Bool
     for whether the mail already existed or has been freshly added (true for having been
     freshly added).
     */
    public static func quickInsertOrUpdate(
        pantomimeMessage message: CWIMAPMessage,
        account: CdAccount) -> CdMessage? {
        guard let folderName = message.folder()?.name() else {
            return nil
        }
        guard let folder = account.folder(byName: folderName) else {
            return nil
        }
        
        let mail = existing(pantomimeMessage: message) ??
            CdMessage.create()
        
        mail.parent = folder
        mail.bodyFetched = message.isInitialized()
        mail.received = message.receivedDate() as NSDate?
        mail.shortMessage = message.subject()
        mail.uuid = message.messageID()
        mail.uid = Int32(message.uid())
        
        let imap = mail.imap ?? CdImapFields.create()
        mail.imap = imap
        
        imap.messageNumber = Int32(message.messageNumber())
        imap.mimeBoundary = (message.boundary() as NSData?)?.asciiString()
        
        // sync flags
        let flags = message.flags()
        imap.flagsFromServer = Int16(flags.rawFlagsAsShort())
        imap.flagsCurrent = imap.flagsFromServer
        imap.flagSeen = flags.contain(.seen)
        imap.flagAnswered = flags.contain(.answered)
        imap.flagFlagged = flags.contain(.flagged)
        imap.flagDeleted = flags.contain(.deleted)
        imap.flagDraft = flags.contain(.draft)
        imap.flagRecent = flags.contain(.recent)
        
        return mail
    }
    
    /**
     Converts a pantomime mail to a Message and stores it.
     Don't use this on the main thread as there is potentially a lot of processing involved
     (e.g., parsing of HTML and/or attachments).
     - Parameter message: The pantomime message to insert.
     - Parameter accountEmail: The email for the account this email is supposed to be stored
     for.
     - Parameter forceParseAttachments: If true, this will parse the attachments even
     if the pantomime has not been initialized yet (useful for testing only).
     - Returns: The newly created or updated Message
     */
    public static func insertOrUpdate(
        pantomimeMessage message: CWIMAPMessage, account: CdAccount,
        forceParseAttachments: Bool = false) -> CdMessage? {
        let quickMail = quickInsertOrUpdate(pantomimeMessage: message, account: account)
        guard let mail = quickMail else {
            return nil
        }
        
        if let from = message.from() {
            let contactsFrom = add(contacts: [from])
            let email = from.address()
            let c = contactsFrom[email!]
            mail.from = c
        }
        
        mail.bodyFetched = message.isInitialized()
        
        let addresses = message.recipients() as! [CWInternetAddress]
        let contacts = add(contacts: addresses)
        
        let tos: NSMutableOrderedSet = []
        let ccs: NSMutableOrderedSet = []
        let bccs: NSMutableOrderedSet = []
        for addr in addresses {
            switch addr.type() {
            case .toRecipient:
                tos.add(contacts[addr.address()]!)
            case .ccRecipient:
                ccs.add(contacts[addr.address()]!)
            case .bccRecipient:
                bccs.add(contacts[addr.address()]!)
            default:
                Log.warn(component: "Message",
                         "Unsupported recipient type \(addr.type()) for \(addr.address())")
            }
        }
        mail.to = tos
        mail.cc = ccs
        mail.bcc = bccs
        
        let referenceStrings = NSMutableOrderedSet()
        if let pantomimeRefs = message.allReferences() {
            for ref in pantomimeRefs {
                referenceStrings.add(ref)
            }
        }
        // Append inReplyTo to references (https://cr.yp.to/immhf/thread.html)
        if let inReplyTo = message.inReplyTo() {
            referenceStrings.add(inReplyTo)
        }
        
        for refID in referenceStrings {
            let ref = insertOrUpdateMessageReference(refID as! String)
            mail.addToReferences(ref)
        }
        
        let imap = mail.imap ?? CdImapFields.create()
        mail.imap = imap
        
        imap.contentType = message.contentType()
        
        if forceParseAttachments || mail.bodyFetched {
            // Parsing attachments only makes sense once pantomime has received the
            // mail body. Same goes for the snippet.
            addAttachmentsFromPantomimePart(message, targetMail: mail, level: 0)
        }
        
        return mail
    }
    
    /**
     - Returns: An existing message that matches the given pantomime one.
     */
    static func existing(pantomimeMessage: CWIMAPMessage) -> CdMessage? {
        guard let mid = pantomimeMessage.messageID() else {
            return nil
        }
        return CdMessage.first(with: "uuid", value: mid)
    }
    
    static func add(contacts: [CWInternetAddress]) -> [String: CdIdentity] {
        var added: [String: CdIdentity] = [:]
        for address in contacts {
            let addr = CdIdentity.first(with: "address", value: address.address()) ??
                CdIdentity.create(with: ["address": address.address(), "isMySelf": false])
            addr.userName = address.personal()
            added[address.address()] = addr
        }
        return added
    }
    
    static func insertOrUpdateMessageReference(_ messageID: String) -> CdMessageReference {
        let ref = CdMessageReference.firstOrCreate(with: "reference", value: messageID)
        ref.message = CdMessage.first(with: "messageID", value: messageID)
        return ref
    }
    
    /**
     Inserts or updates a pantomime message into the data store with only the bare minimum
     of data.
     - Returns: A tuple consisting of the message inserted and a Bool denoting
     whether this message was just inserted (true)
     or an existing message was found (false).
     */
    static func addAttachmentsFromPantomimePart(
        _ part: CWPart, targetMail: CdMessage, level: Int) {
        guard let content = part.content() else {
            return
        }
        
        let isText = part.contentType()?.lowercased() == Constants.contentTypeText
        let isHtml = part.contentType()?.lowercased() == Constants.contentTypeHtml
        var contentData: Data?
        if let message = content as? CWMessage {
            contentData = message.dataValue()
        } else if let string = content as? NSString {
            contentData = string.data(using: String.Encoding.ascii.rawValue)
        } else if let data = content as? Data {
            contentData = data
        }
        if let data = contentData {
            if isText && level < 3 && targetMail.longMessage == nil &&
                MiscUtil.isEmptyString(part.filename()) {
                targetMail.longMessage = data.toStringWithIANACharset(part.charset())
            } else if isHtml && level < 3 && targetMail.longMessageFormatted == nil &&
                MiscUtil.isEmptyString(part.filename()) {
                targetMail.longMessageFormatted = data.toStringWithIANACharset(part.charset())
            } else {
                let attachment = insertAttachment(
                    contentType: part.contentType(), filename: part.filename(), data: data)
                targetMail.addAttachment(attachment)
            }
        }
        
        if let multiPart = content as? CWMIMEMultipart {
            for i in 0..<multiPart.count() {
                let subPart = multiPart.part(at: UInt(i))
                addAttachmentsFromPantomimePart(subPart, targetMail: targetMail, level: level + 1)
            }
        }
    }
    
    static func insertAttachment(
        contentType: String?, filename: String?, data: Data) -> CdAttachment {
        let attachment = CdAttachment.create(with: ["data": data, "size": data.count])
        attachment.mimeType = contentType
        attachment.fileName = filename
        return attachment
    }

}
