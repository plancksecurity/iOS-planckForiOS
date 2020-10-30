//
//  CdMessage+Pantomime.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox
import PantomimeFramework
import PEPObjCAdapterFramework

public typealias ImapStoreCommand = (command: String, pantomimeDict:[AnyHashable: Any])

public enum UpdateFlagsMode: String {
    case add = "+"
    case remove = "-"
}

extension CdMessage {
    /**
     - Returns: A `CWFlags object` for the given `NSNumber`
     */
    static public func pantomimeFlagsFromNumber(_ flags: Int16) -> CWFlags {
        if let fl = PantomimeFlag(rawValue: UInt(flags)) {
            return CWFlags(flags: fl)
        }
        Log.shared.error("Could not convert %d to PantomimeFlag", flags)
        return CWFlags()
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
    static public func pantomimeFlags(flagsInt16: Int16) -> CWFlags {
        if let fl = PantomimeFlag(rawValue: UInt(flagsInt16)) {
            return CWFlags(flags: fl)
        }
        Log.shared.error("Could not convert %d to PantomimeFlag", flagsInt16)
        return CWFlags()
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
            Log.shared.errorAndCrash("imap == nil")
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
                if let tref = ref as? CdMessageReference, let refString: String = tref.reference {
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
        return PEPUtils.pantomime(cdMessage: self)
    }

    func internetAddressFromContact(_ contact: CdIdentity) -> CWInternetAddress {
        let address = contact.address ?? "" // CdIdentity.address is not optional in the DB
        return CWInternetAddress.init(personal: contact.userName, address: address)
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
     */
    public func updateFromServer(cwFlags: CWFlags, context: NSManagedObjectContext) {
        // Since we frequently sync the flags, don't modify anything
        // if the version from the server has already been known,
        // since this could overwrite changes just made by the user.
        if cwFlags.rawFlagsAsShort() == imap?.serverFlags?.rawFlagsAsShort() {
            return
        }

        let theImap = imapFields(context: context)

        let haveLocalChanges =
            theImap.localFlags?.rawFlagsAsShort() != theImap.serverFlags?.rawFlagsAsShort()

        let serverFlags = theImap.serverFlags ?? CdImapFlags(context: context)
        theImap.serverFlags = serverFlags

        let localFlags = theImap.localFlags ?? CdImapFlags(context: context)
        theImap.localFlags = localFlags

        if haveLocalChanges {
            mergeOnConflict(localFlags: localFlags, serverFlags: serverFlags,
                            newServerFlags: cwFlags)
        } else {
            localFlags.update(cwFlags: cwFlags)
        }

        serverFlags.update(cwFlags: cwFlags)

        // Update imap to trigger FetchedResultsController
        let newServerFlags = serverFlags.clone(context: context, deleteOriginal: true)
        let newLocalFlags = localFlags.clone(context: context, deleteOriginal: true)

        context.delete(theImap)

        let newImapFields = CdImapFields(context: context)
        newImapFields.serverFlags = newServerFlags
        newImapFields.localFlags = newLocalFlags

        // Re-set imap directly on the message to trigger NSFetchedResultsController
        imap =  newImapFields
    }

    /**
     Tries to merge IMAP flags, basically taking into
     account which flags were changed locally if it makes any difference.
     */
    func mergeOnConflict(localFlags: CdImapFlags,
                         serverFlags: CdImapFlags,
                         newServerFlags: CWFlags) {
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
    }

    /**
     Quickly inserts essential parts of a pantomime message into the store.
     Useful for networking, where inserts should be quick and the persistent store
     correct (especially in terms of UIDs, messageNumbers etc.)
     - Returns: The message just created or updated, or nil.
     */
    static func quickInsertOrUpdate(pantomimeMessage message: CWIMAPMessage,
                                    account: CdAccount,
                                    messageUpdate: CWMessageUpdate,
                                    context: NSManagedObjectContext) -> CdMessage? {
        guard
            let folderName = message.folder()?.name(),
            let folder = account.folder(byName: folderName, context: context)
            else {
                return nil
        }

        guard let account = context.object(with: account.objectID) as? CdAccount
            else {
                Log.shared.errorAndCrash(message: "Need an existing account")
                return nil
        }

        var isUpdate = false
        let mail: CdMessage
        if let existing = existing(pantomimeMessage: message, inAccount: account, context: context) {
            mail = existing
            isUpdate = true
        } else {
            mail = CdMessage.newIncomingMessage(context: context)
        }

        let oldMSN = mail.imapFields(context: context).messageNumber
        let newMSN = Int32(message.messageNumber())

        // Bail out quickly if there is only a MSN change
        if messageUpdate.isMsnOnly() {
            mail.imapFields(context: context).messageNumber = newMSN
            return mail
        }

        mail.updateFromServer(cwFlags: message.flags(), context: context)

        // Bail out quickly if there is only a flag change needed
        if messageUpdate.isFlagsOnly() {
            guard isUpdate else {
                Log.shared.errorAndCrash(
                    "If only flags did change, the message must have existed before. Thus it must be an update.")
                return nil
            }
            if oldMSN != newMSN {
                mail.imapFields(context: context).messageNumber = newMSN
            }
            return mail
        }

        if !moreMessagesThanRequested(mail: mail, messageUpdate: messageUpdate) {
            mail.parent = folder
            mail.sent = message.originationDate() ?? Date()
            mail.shortMessage = message.subject()

            mail.uuid = message.messageID()
            mail.uid = Int32(message.uid())

            let imap = mail.imapFields(context: context)

            imap.messageNumber = Int32(message.messageNumber())
            imap.mimeBoundary = (message.boundary() as NSData?)?.asciiString()
        }

        return mail
    }

    /**
     Converts a pantomime mail to a Message and stores it.
     Don't use this on the main thread as there is potentially a lot of processing involved
     (e.g., parsing of HTML and/or attachments).
     - Parameter message: The pantomime message to insert.
     - Parameter account: The account this email is supposed to be stored for.
     - Returns: The newly created or updated Message
     */
    @discardableResult
    static func insertOrUpdate(pantomimeMessage: CWIMAPMessage,
                               account: CdAccount,
                               messageUpdate: CWMessageUpdate,
                               context: NSManagedObjectContext) -> CdMessage? {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        guard let mail = quickInsertOrUpdate(pantomimeMessage: pantomimeMessage,
                                             account: account,
                                             messageUpdate: messageUpdate,
                                             context: context)
            else {
                return nil
        }

        if messageUpdate.isFlagsOnly() || messageUpdate.isMsnOnly() {
            context.saveAndLogErrors()
            return mail
        }

        if moreMessagesThanRequested(mail: mail, messageUpdate: messageUpdate) {
            // This is a contradiction in itself, a new message that already existed.
            // Can happen with yahoo IMAP servers when they send more messages in
            // FETCH responses than requested.
            Log.shared.warn(
                "ignoring rfc2822 update for already decrypted message")
            context.saveAndLogErrors()
            return mail
        }

        if let cwFrom = pantomimeMessage.from() {
            if let cdIdentity = cdIdentity(pantomimeAddress: cwFrom, context: context) {
                mail.from = cdIdentity
            }
        }

        if let addresses = pantomimeMessage.recipients() as? [CWInternetAddress] {
            let tos: NSMutableOrderedSet = []
            let ccs: NSMutableOrderedSet = []
            let bccs: NSMutableOrderedSet = []
            for cwAddr in addresses {
                guard let cdAddr = cdIdentity(pantomimeAddress: cwAddr, context: context) else {
                    continue
                }

                switch cwAddr.type() {
                case .toRecipient:
                    tos.add(cdAddr)
                case .ccRecipient:
                    ccs.add(cdAddr)
                case .bccRecipient:
                    bccs.add(cdAddr)
                default:
                    // Type we are not interested in like PantomimeResentToRecipient
                    continue
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
        mail.replace(referenceStrings: referenceStrings.array, context: context)

        if let oneOrMoreInReplyTos = pantomimeMessage.inReplyTo() {
            // TODO: How does pantomime handle more than one in-reply-to?
            let _ = mail.addMessageReference(messageID: oneOrMoreInReplyTos,
                                             referenceType: .inReplyTo,
                                             context: context)
        }

        let imap = mail.imapFields(context: context)

        imap.contentType = pantomimeMessage.contentType()

        // If the cdMessage contains attachments already, it is not a new- but an updated mail that
        // accidentally made its way until here.
        // Do *not* add the attachments again.
        if !containsAttachments(cdMessage: mail) {
            addAttachmentsFromPantomimePart(pantomimeMessage,
                                            targetMail: mail,
                                            context: context)
        }

        store(headerFieldNames: ["X-pEp-Version",
                                 "X-EncStatus",
                                 "X-KeyList",
                                 kPepHeaderAutoConsume],
              pantomimeMessage: pantomimeMessage,
              cdMessage: mail,
              context: context)

        context.saveAndLogErrors()

        return mail
    }

    static private func containsAttachments(cdMessage: CdMessage) -> Bool {
        guard let attachments = cdMessage.attachments else {
            return false
        }
        return attachments.count > 0
    }

    static func store(headerFieldNames: [String],
                      pantomimeMessage: CWIMAPMessage,
                      cdMessage: CdMessage,
                      context: NSManagedObjectContext) {
        var headerFields = [CdHeaderField]()
        for headerName in headerFieldNames {
            if let value = pantomimeMessage.headerValue(forName: headerName) as? String {
                let hf = CdHeaderField(context: context)
                hf.name = headerName
                hf.value = value
                hf.message = cdMessage
                headerFields.append(hf)
            }
        }

        if !headerFields.isEmpty {
            cdMessage.optionalFields = NSOrderedSet(array: headerFields)
        } else {
            cdMessage.optionalFields = nil
        }
        CdHeaderField.deleteOrphans(context: context)
    }

    //!!!: docs please!
    static private func moreMessagesThanRequested(mail: CdMessage,
                                                  messageUpdate: CWMessageUpdate) -> Bool {
        return mail.pEpRating != PEPRating.undefined.rawValue && messageUpdate.rfc822
    }

    /**
     Will match existing messages.
     Message ID alone is not sufficient, trashed emails can and will exist in more than one folder.
     - Returns: An existing message that matches the given pantomime one.
     */
    static private func existing(pantomimeMessage: CWIMAPMessage,
                                 inAccount account: CdAccount,
                                 context: NSManagedObjectContext) -> CdMessage? {
        guard let safeAccount = context.object(with: account.objectID) as? CdAccount
            else {
                return nil
        }
        return search(message:pantomimeMessage, inAccount: safeAccount, context: context)
    }

    /// Try to get the best possible match possible for given data.
    /// Best match priority:
    /// 1) UID + foldername
    /// 2) UUID + foldername
    /// 3) UUID only
    ///
    /// - Parameter message: message to search for
    /// - Returns: existing message
    static func search(message: CWIMAPMessage,
                       inAccount account: CdAccount,
                       context: NSManagedObjectContext) -> CdMessage? {
        let uid = Int32(message.uid())
        guard let uuid = message.messageID() else {
            Log.shared.errorAndCrash("No UUID")
            return nil
        }
        return search(uid: uid,
                      uuid: uuid,
                      folderName: message.folder()?.name(),
                      inAccount: account,
                      context: context)
    }

    static func cdIdentity(pantomimeAddress: CWInternetAddress,
                           context: NSManagedObjectContext) -> CdIdentity? {
        let address = pantomimeAddress.address().fullyUnquoted()
        let userName = pantomimeAddress.personal()?.fullyUnquoted()

        if address == "" {
            // There are malformed headers like "To: Peter Falk <>" in the wild which endup in
            // address == ""
            // We must not save them in out database, thus we ignore those identities.
            // See IOS-1778.
            //
            // Fun fact: The only known sender of those invalid headers is Facebook, sending to news
            // groups. Maybe they consider that as "anonimysed" :-)
            Log.shared.warn("Empty address: \"%@\"", pantomimeAddress.address())
            return nil
        }

        var identity: CdIdentity
        if let existing = CdIdentity.search(address: address, context: context) {
            identity = existing
            if !identity.isMySelf {
                identity.userName = userName
            }
        } else {
            // this identity has to be created
            identity = CdIdentity(context: context)
            identity.address = address
            identity.userName = userName
        }
        return identity
    }

    /**
     Adds pantomime attachments to a `CdMessage`.
     */
    static func addAttachmentsFromPantomimePart(_ part: CWPart,
                                                targetMail: CdMessage,
                                                level: Int = 0,
                                                context: NSManagedObjectContext) {
        guard let content = part.content() else {
            return
        }

        let isText = part.contentType()?.lowercased() == MimeTypeUtils.MimeType.plainText.rawValue
        let isHtml = part.contentType()?.lowercased() == MimeTypeUtils.MimeType.html.rawValue
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
            } else if isText && targetMail.longMessage == nil &&
                MiscUtil.isEmptyString(part.filename()) {
                targetMail.longMessage = data.toStringWithIANACharset(part.charset())
            } else if isHtml && targetMail.longMessageFormatted == nil &&
                MiscUtil.isEmptyString(part.filename()) {
                targetMail.longMessageFormatted = data.toStringWithIANACharset(part.charset())
            } else {
                // we
                let contentDispRawValue =
                    CdAttachment.contentDispositionRawValue(from: part.contentDisposition())
                targetMail.insertAttachment(contentType: part.contentType(),
                                            filename: part.filename(),
                                            contentID: part.contentID(),
                                            data: data,
                                            contentDispositionRawValue: contentDispRawValue)
            }
        }

        if let multiPart = content as? CWMIMEMultipart {
            for i in 0..<multiPart.count() {
                let subPart = multiPart.part(at: UInt(i))
                addAttachmentsFromPantomimePart(subPart,
                                                targetMail: targetMail,
                                                level: level + 1,
                                                context: context)
            }
        }
    }
}
