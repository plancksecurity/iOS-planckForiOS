//
//  CdMessage+Pantomime.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/11/16.
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
    
    /**
     - Returns: `flags` as `CWFlags`
     */
    public func pantomimeFlags() -> CWFlags {
        updateCurrentFlags()
        if let theImap = imap {
            return CdMessage.pantomimeFlagsFromNumber(theImap.flagsCurrent)
        } else {
            return CWFlags()
        }
    }

    /**
     - Returns: `flagsFromServer` as `CWFlags`
     */
    public func pantomimeFlagsFromServer() -> CWFlags {
        return CdMessage.pantomimeFlagsFromNumber(imap!.flagsFromServer)
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
        updateCurrentFlags()

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
     Convert the `Message` into an `CWIMAPMessage`, belonging to the given folder.
     - Note: This does not handle attachments and many other fields.
     *It's just for quickly interfacing with Pantomime.*
     */
    func pantomime(folder: CWIMAPFolder) -> CWIMAPMessage {
        let msg = CWIMAPMessage.init()

        if let date = sent {
            msg.setOriginationDate(date as Date)
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

    public func pantomime() -> CWIMAPMessage {
        return PEPUtil.pantomime(cdMessage: self)
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

    public func updateFromServer(flags: CWFlags) {
        let theImap = imap ?? CdImapFields.create()
        imap = theImap

        theImap.flagsFromServer = Int16(flags.rawFlagsAsShort())
        theImap.flagSeen = flags.contain(.seen)
        theImap.flagAnswered = flags.contain(.answered)
        theImap.flagFlagged = flags.contain(.flagged)
        theImap.flagDeleted = flags.contain(.deleted)
        theImap.flagDraft = flags.contain(.draft)
        theImap.flagRecent = flags.contain(.recent)
    }

    /**
     Quickly inserts essential parts of a pantomime message into the store.
     Useful for networking, where inserts should be quick and the persistent store
     correct (especially in terms of UIDs, messageNumbers etc.)
     - Returns: The message just created or updated, or nil.
     */
    public static func quickInsertOrUpdate(
        pantomimeMessage message: CWIMAPMessage,
        account: CdAccount, messageUpdate: CWMessageUpdate) -> CdMessage? {
        guard let folderName = message.folder()?.name() else {
            return nil
        }
        guard let folder = account.folder(byName: folderName) else {
            return nil
        }

        // Bail out quickly if there is only a flag change needed
        if messageUpdate.isFlagsOnly() {
            if let mail = existing(pantomimeMessage: message) {
                if (mail.imap?.flagsCurrent ?? 0) != message.flags().rawFlagsAsShort() {
                    mail.updateFromServer(flags: message.flags())
                }
                return mail
            }
            return nil
        }

        let mail = existing(pantomimeMessage: message) ??
            CdMessage.create()

        mail.parent = folder
        mail.bodyFetched = message.isInitialized()
        mail.sent = message.originationDate() as NSDate?
        mail.shortMessage = message.subject()
        mail.uuid = message.messageID()
        mail.uid = Int32(message.uid())

        let imap = mail.imap ?? CdImapFields.create()
        mail.imap = imap

        imap.messageNumber = Int32(message.messageNumber())
        imap.mimeBoundary = (message.boundary() as NSData?)?.asciiString()

        mail.updateFromServer(flags: message.flags())

        return mail
    }

    /**
     Converts a pantomime mail to a Message and stores it.
     Don't use this on the main thread as there is potentially a lot of processing involved
     (e.g., parsing of HTML and/or attachments).
     - Parameter message: The pantomime message to insert.
     - Parameter account: The account this email is supposed to be stored for.
     - Parameter forceParseAttachments: If true, this will parse the attachments even
     if the pantomime has not been initialized yet (useful for testing).
     - Returns: The newly created or updated Message
     */
    public static func insertOrUpdate(
        pantomimeMessage message: CWIMAPMessage, account: CdAccount,
        messageUpdate: CWMessageUpdate, forceParseAttachments: Bool = false) -> CdMessage? {
        guard let mail = quickInsertOrUpdate(
            pantomimeMessage: message, account: account, messageUpdate: messageUpdate) else {
                return nil
        }

        if messageUpdate.isFlagsOnly() {
            return mail
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
                Log.warn(
                    component: "Message",
                    content: "Unsupported recipient type \(addr.type()) for \(addr.address())")
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
            mail.addReference(cdMessageReference: ref)
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
        ref.message = CdMessage.first(with: "uuid", value: messageID)
        return ref
    }

    /**
     Adds pantomime attachments to a `CdMessage`.
     */
    static func addAttachmentsFromPantomimePart(
        _ part: CWPart, targetMail: CdMessage, level: Int) {
        Log.info(component: #function, content: "Parsing level \(level) \(part)")
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
}
