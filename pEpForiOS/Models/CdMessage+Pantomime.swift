//
//  CdMessage+Pantomime.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

public typealias ImapStoreCommand = (command: String, pantomimeDict:[AnyHashable: Any])

    public enum UpdateFlagsMode: String {
        case add = "+"
        case remove = "-"
    }

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
        if let theFlags = imap?.localFlags {
            return theFlags.pantomimeFlags() ?? CWFlags()
        } else {
            return CWFlags()
        }
    }

    /**
     - Returns: `flagsFromServer` as `CWFlags`
     */
    public func pantomimeflagsFromServer() -> CWFlags {
        if let theFlags = imap?.serverFlags {
            return theFlags.pantomimeFlags() ?? CWFlags()
        } else {
            return CWFlags()
        }
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

    private func pantomimeInfoDict() -> [AnyHashable: Any] {
        // Construct a very minimal pantomime dummy for the info dictionary
        let pantomimeMail = CWIMAPMessage.init()
        pantomimeMail.setUID(UInt(uid))
        var dict: [AnyHashable: Any] = [PantomimeMessagesKey: NSArray.init(object: pantomimeMail)]

        guard let imap = imap else {
            Log.shared.errorAndCrash(component:"\(#function)[\(#line)]", errorString: "imap == nil")
            return [AnyHashable: Any]()
        }

        if let currentFlags = imap.localFlags?.rawFlagsAsShort() {
            dict[PantomimeFlagsKey] = CdMessage.pantomimeFlags(flagsInt16: currentFlags)
        }

        return dict
    }

    /// Creates a tuple consisting of an IMAP command string for syncing flags that have been 
    /// modified by the client for this message, and a dictionary suitable for using pantomime 
    /// for the actual execution.
    ///
    /// - note: Flags added and flags removed by the client use different commands. 
    ///         Which to use can be chosen by the `mode` parameted.
    ///
    /// - seealso: [RFC4549](https://tools.ietf.org/html/rfc4549#section-4.2.3)
    ///
    /// - Parameter mode: mode to create command for
    /// - Returns: tuple consisting of an IMAP command string for syncing flags and a dictionary 
    ///    suitable for using pantomime
    /// for the actual execution
    public func storeCommandForUpdateFlags(to mode: UpdateFlagsMode) -> ImapStoreCommand? {
        guard imap != nil else {
            return nil
        }

        let flags: ImapFlagsBits!

        switch mode {
        case .add:
            flags = flagsToAdd()
        case .remove:
            flags = flagsToRemove()
        }

        if flags.imapNoRelevantFlagSet() {
            return nil
        }

        let prefixFlagsSilent = mode.rawValue

        let flagsString = CdMessage.flagsString(flagsInt16: flags)
        let result = "UID STORE \(uid) \(prefixFlagsSilent)FLAGS.SILENT (\(flagsString))"

        let dict = pantomimeInfoDict()

        return ImapStoreCommand(command: result, pantomimeDict: dict)
    }

    /// Returns the flags that have to be added on server, represented in bits.
    /// A set bit (1) means it has to be added.
    ///
    /// - Returns: flags to add
    private func flagsToAdd() -> Int16 {
        let diff = flagsDiff()

        if !diff.imapAnyRelevantFlagSet() {
            return ImapFlagsBits.imapNoFlagsSet()
        }

        guard let flagsCurrent = imap?.localFlags?.rawFlagsAsShort() else {
            return ImapFlagsBits.imapNoFlagsSet()
        }

        var flagsToRemove = ImapFlagsBits.imapNoFlagsSet()

        if diff.imapFlagBitIsSet(flagbit: .answered) && flagsCurrent.imapFlagBitIsSet(flagbit: .answered) {
            flagsToRemove += ImapFlagBit.answered.rawValue
        }
        if diff.imapFlagBitIsSet(flagbit: .deleted) && flagsCurrent.imapFlagBitIsSet(flagbit: .deleted) {
            flagsToRemove += ImapFlagBit.deleted.rawValue
        }
        if diff.imapFlagBitIsSet(flagbit: .draft) && flagsCurrent.imapFlagBitIsSet(flagbit: .draft) {
            flagsToRemove += ImapFlagBit.draft.rawValue
        }
        if diff.imapFlagBitIsSet(flagbit: .flagged) && flagsCurrent.imapFlagBitIsSet(flagbit: .flagged) {
            flagsToRemove += ImapFlagBit.flagged.rawValue
        }
        // The "Recent" flag is intentionally not handled, as it is modified by the server only.
        if diff.imapFlagBitIsSet(flagbit: .seen) && flagsCurrent.imapFlagBitIsSet(flagbit: .seen) {
            flagsToRemove += ImapFlagBit.seen.rawValue
        }

        return flagsToRemove
    }

    /// Returns the flags that have to be removed on server, represented in bits.
    /// A set bit (1) means it has to be removed.
    ///
    /// - Returns: flags to remove
    private func flagsToRemove() -> Int16 {
        let diff = flagsDiff()

        if !diff.imapAnyRelevantFlagSet() {
            return ImapFlagsBits.imapNoFlagsSet()
        }

        guard let flagsCurrent = imap?.localFlags?.rawFlagsAsShort() else {
            return ImapFlagsBits.imapNoFlagsSet()
        }

        var flagsToRemove = ImapFlagsBits.imapNoFlagsSet()

        if diff.imapFlagBitIsSet(flagbit: .answered) && !flagsCurrent.imapFlagBitIsSet(flagbit: .answered) {
            flagsToRemove += ImapFlagBit.answered.rawValue
        }
        if diff.imapFlagBitIsSet(flagbit: .deleted) && !flagsCurrent.imapFlagBitIsSet(flagbit: .deleted) {
            flagsToRemove += ImapFlagBit.deleted.rawValue
        }
        if diff.imapFlagBitIsSet(flagbit: .draft) && !flagsCurrent.imapFlagBitIsSet(flagbit: .draft) {
            flagsToRemove += ImapFlagBit.draft.rawValue
        }
        if diff.imapFlagBitIsSet(flagbit: .flagged) && !flagsCurrent.imapFlagBitIsSet(flagbit: .flagged) {
            flagsToRemove += ImapFlagBit.flagged.rawValue
        }
        // The "Recent" flag is intentionally not handled, as it is modified by the server only.
        if diff.imapFlagBitIsSet(flagbit: .seen) && !flagsCurrent.imapFlagBitIsSet(flagbit: .seen) {
            flagsToRemove += ImapFlagBit.seen.rawValue
        }

        return flagsToRemove
    }

    /// Returns the flags that differ in between flagsCurrent and flagsFromServer, represented in bits.
    /// A set bit (1) means it differs.
    ///
    /// Find more details about the semantic of those bits in Int16+ImapFlagBits.swift
    ///
    /// - Returns: flags that differ
    private func flagsDiff() -> Int16 {
        guard let flagsCurrent = imap?.localFlags?.rawFlagsAsShort() else {
            return ImapFlagsBits.imapNoFlagsSet()
        }

        var flagsFromServer = ImapFlagsBits.imapNoFlagsSet()
        if let flags = imap?.serverFlags?.rawFlagsAsShort() {
            flagsFromServer = flags
        }

        return flagsCurrent ^ flagsFromServer
    }

    /**
     Convert the `Message` into an `CWIMAPMessage`, belonging to the given folder.
     - Note: This does not handle attachments and many other fields.
     *It's just for quickly interfacing with Pantomime.*
     */
    func pantomimeQuick(folder: CWIMAPFolder) -> CWIMAPMessage {
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
        if let flags = imap?.localFlags?.rawFlagsAsShort() {
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

    /**
     Stores server flags that have changed.
     * If the server flags have already been known, nothing is done.
     * Otherwise, the new server flags are stored.
       * If there were no local flag changes (in respect to the previous server flags version),
         the local flags will then be set to the same value.
       * If there were local changes, then the local flags will not change.
     - Returns: true if the local flags were updated.
     */
    public func updateFromServer(cwFlags: CWFlags) -> Bool {
        // Since we frequently sync the flags, don't modify anything
        // if the version from the server has already been known,
        // since this could overwrite changes just made by the user.
        if cwFlags.rawFlagsAsShort() == imap?.serverFlags?.rawFlagsAsShort() {
            return false
        }

        let theImap = imapFields()

        let haveLocalChanges =
            theImap.localFlags?.rawFlagsAsShort() != theImap.serverFlags?.rawFlagsAsShort()

        let serverFlags = theImap.serverFlags ?? CdImapFlags.create()
        theImap.serverFlags = serverFlags

        let localFlags = theImap.localFlags ?? CdImapFlags.create()
        theImap.localFlags = localFlags

        var changedLocalFlags = false
        if haveLocalChanges {
            changedLocalFlags =  mergeOnConflict(localFlags: localFlags, serverFlags: serverFlags,
                                                 newServerFlags: cwFlags)
        } else {
            localFlags.update(cwFlags: cwFlags)
            changedLocalFlags = true
        }

        serverFlags.update(cwFlags: cwFlags)
        if cwFlags.contain(.deleted) {
            Log.info(component: #function, content: "Message with flag deleted")
            if let msg = self.message() {
                MessageModelConfig.messageFolderDelegate?.didChange(messageFolder: msg)
            }
        }

        return changedLocalFlags
    }

    /**
     Tries to merge IMAP flags, basically taking into
     account which flags were changed locally if it makes any difference.
     */
    func mergeOnConflict(localFlags: CdImapFlags, serverFlags: CdImapFlags,
                         newServerFlags: CWFlags) -> Bool {
        localFlags.flagAnswered = localFlags.flagAnswered || serverFlags.flagAnswered ||
            newServerFlags.contain(.answered)
        localFlags.flagDraft = localFlags.flagDraft || serverFlags.flagDraft ||
            newServerFlags.contain(.draft)
        if localFlags.flagFlagged == serverFlags.flagFlagged {
            localFlags.flagFlagged = newServerFlags.contain(.flagged)
        }
        localFlags.flagRecent = newServerFlags.contain(.recent)
        if localFlags.flagSeen == serverFlags.flagSeen {
            localFlags.flagSeen = newServerFlags.contain(.seen)
        }
        localFlags.flagDeleted = localFlags.flagDeleted || serverFlags.flagDeleted ||
            newServerFlags.contain(.deleted)
        return localFlags.rawFlagsAsShort() != newServerFlags.rawFlagsAsShort()
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
                if mail.updateFromServer(cwFlags: message.flags()) {
                    Record.saveAndWait()
                    if mail.pEpRating != pEpRatingNone {
                        mail.serialNumber = mail.serialNumber + 1
                        if let msg = mail.message() {
                            MessageModelConfig.messageFolderDelegate?.didChange(messageFolder: msg)
                        }
                    }
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

        let imap = mail.imapFields()

        imap.messageNumber = Int32(message.messageNumber())
        imap.mimeBoundary = (message.boundary() as NSData?)?.asciiString()

        let _ = mail.updateFromServer(cwFlags: message.flags())

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
        pantomimeMessage: CWIMAPMessage, account: CdAccount,
        messageUpdate: CWMessageUpdate, forceParseAttachments: Bool = false) -> CdMessage? {
        guard let mail = quickInsertOrUpdate(
            pantomimeMessage: pantomimeMessage, account: account, messageUpdate: messageUpdate)
            else {
                return nil
        }

        if messageUpdate.isFlagsOnly() {
            return mail
        }

        if mail.pEpRating != PEPUtil.pEpRatingNone && messageUpdate.rfc822 {
            // This is a contradiction in itself, a new message that already existed.
            // Can happen with yahoo IMAP servers when they send more messages in
            // FETCH responses than requested.
            Log.warn(component: #function,
                     content: "ignoring rfc2822 update for already decrypted message")
            return mail
        }

        if let from = pantomimeMessage.from() {
            mail.from = cdIdentity(pantomimeAddress: from)
        }

        mail.bodyFetched = pantomimeMessage.isInitialized()

        if let addresses = pantomimeMessage.recipients() as? [CWInternetAddress] {
            let tos: NSMutableOrderedSet = []
            let ccs: NSMutableOrderedSet = []
            let bccs: NSMutableOrderedSet = []
            for addr in addresses {
                switch addr.type() {
                case .toRecipient:
                    tos.add(cdIdentity(pantomimeAddress: addr))
                case .ccRecipient:
                    ccs.add(cdIdentity(pantomimeAddress: addr))
                case .bccRecipient:
                    bccs.add(cdIdentity(pantomimeAddress: addr))
                default:
                    Log.warn(
                        component: "Message",
                        content: "Unsupported recipient type \(addr.type()) for \(addr.address())")
                }
            }
            mail.to = tos
            mail.cc = ccs
            mail.bcc = bccs
        }

        let referenceStrings = MutableOrderedSet<String>()
        if let pantomimeRefs = pantomimeMessage.allReferences() as? [String] {
            for ref in pantomimeRefs {
                referenceStrings.append(ref)
            }
        }
        // Append inReplyTo to references (https://cr.yp.to/immhf/thread.html)
        if let inReplyTo = pantomimeMessage.inReplyTo() {
            referenceStrings.append(inReplyTo)
        }

        mail.replace(referenceStrings: referenceStrings.array)

        mail.dumpReferences()

        let imap = mail.imapFields()

        imap.contentType = pantomimeMessage.contentType()

        if forceParseAttachments || mail.bodyFetched {
            // Parsing attachments only makes sense once pantomime has received the
            // mail body. Same goes for the snippet.
            addAttachmentsFromPantomimePart(pantomimeMessage, targetMail: mail, level: 0)
        }

        Record.saveAndWait()
        if mail.pEpRating != PEPUtil.pEpRatingNone,
            let msg = mail.message() {
            if msg.isGhost {
                Log.info(component: #function, content: "Message ghost from full insert?")
            }
            MessageModelConfig.messageFolderDelegate?.didChange(messageFolder: msg)
        }

        return mail
    }

    /**
     Will match existing messages.
     Message ID alone is not sufficient, trashed emails can and will exist in more than one folder.
     - Returns: An existing message that matches the given pantomime one.
     */
    static private func existing(pantomimeMessage: CWIMAPMessage) -> CdMessage? {
        return search(message:pantomimeMessage)
    }

    /// Try to get the best possible match possible for given data.
    /// Best match priority:
    /// 1) UID + foldername
    /// 2) UUID + foldername
    /// 3) UUID only
    ///
    /// - Parameter message: message to search for
    /// - Returns: existing message
    static public func search(message: CWIMAPMessage) -> CdMessage? {
        let uid = Int32(message.uid())
       return search(uid: uid, uuid: message.messageID(),
                     folderName: message.folder()?.name())
    }

    static func cdIdentity(pantomimeAddress: CWInternetAddress) -> CdIdentity {
        let addr = CdIdentity.first(attribute: "address", value: pantomimeAddress.address()) ??
            CdIdentity.create(attributes: ["address": pantomimeAddress.address(),
                                           "isMySelf": false])
        let identity = Identity.from(cdIdentity: addr)
        if let username = pantomimeAddress.personal() {
            identity.userName = username
        }
        identity.save()
        //addr.userName = pantomimeAddress.personal()
        return addr
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
            if level == 0 && !isText && !isHtml && targetMail.longMessage == nil &&
                MiscUtil.isEmptyString(part.filename()) {
                // some content with unknown content type at the first level must be text
                targetMail.longMessage = data.toStringWithIANACharset(part.charset())
            } else if isText && level < 3 && targetMail.longMessage == nil &&
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
