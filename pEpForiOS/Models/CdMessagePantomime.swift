//
//  CdMessagePantomime.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 08/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

/**
 CdMessage "extension" for dealing with Pantomime (IMAP library).
 - Note: Making this into an actual CdMessage extension was not possible since the unit tests
 were unable to find those static members at the time of writing. This might have changed by now.
 */
open class CdMessagePantomime {
    static let comp = "CdMessagePantomime"

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
        account: CdAccount) -> MessageModel.CdMessage? {
        guard let folderName = message.folder()?.name() else {
            return nil
        }
        guard let folder = account.folder(byName: folderName) else {
            return nil
        }

        let mail = existing(pantomimeMessage: message) ??
            MessageModel.CdMessage.create()

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
        forceParseAttachments: Bool = false) -> MessageModel.CdMessage? {
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
                Log.warn(component: comp,
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
    static func existing(pantomimeMessage: CWIMAPMessage) -> MessageModel.CdMessage? {
        guard let mid = pantomimeMessage.messageID() else {
            return nil
        }
        return MessageModel.CdMessage.first(with: "uuid", value: mid)
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
        ref.message = MessageModel.CdMessage.first(with: "messageID", value: messageID)
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
        _ part: CWPart, targetMail: MessageModel.CdMessage, level: Int) {
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
