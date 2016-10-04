//
//  PEPUtil.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Simple `Hashable` implementation so PEP_rating can be put into dictionaries.
 */
extension PEP_rating: Hashable {
    public var hashValue: Int {
        return Int(rawValue)
    }
}

/**
 For translating integer values into `PEP_rating`.
 */
let pepColorDictionary: [Int32: PEP_rating] =
    [PEP_rating_undefined.rawValue: PEP_rating_undefined,
     PEP_rating_cannot_decrypt.rawValue: PEP_rating_cannot_decrypt,
     PEP_rating_have_no_key.rawValue: PEP_rating_have_no_key,
     PEP_rating_unencrypted.rawValue: PEP_rating_unencrypted,
     PEP_rating_unencrypted_for_some.rawValue:  PEP_rating_unencrypted_for_some,
     PEP_rating_unreliable.rawValue: PEP_rating_unreliable,
     PEP_rating_reliable.rawValue: PEP_rating_reliable,
     PEP_rating_trusted.rawValue: PEP_rating_trusted,
     PEP_rating_trusted_and_anonymized.rawValue: PEP_rating_trusted_and_anonymized,
     PEP_rating_fully_anonymous.rawValue: PEP_rating_fully_anonymous,
     PEP_rating_mistrust.rawValue: PEP_rating_mistrust,
     PEP_rating_b0rken.rawValue: PEP_rating_b0rken,
     PEP_rating_under_attack.rawValue: PEP_rating_under_attack]

/**
 All privacy status strings, i18n ready.
 */
let pepPricacyStatusTranslations: [PEP_rating: (String, String, String)] =
    [PEP_rating_under_attack:
        (NSLocalizedString("Under Attack",
            comment: "Privacy status title"),
            NSLocalizedString("This message is not secure and has been tampered with.",
                comment: "Privacy status explanation"),
            NSLocalizedString("Separately verify the content of this message with your communication partner.",
                comment: "Privacy status suggestion")),
     PEP_rating_b0rken:
        (NSLocalizedString("Ooops: Internal problem",
            comment: "Privacy status title"),
            NSLocalizedString("-",
                comment: "Privacy status explanation"),
            NSLocalizedString("-", comment: "")),
     PEP_rating_mistrust:
        (NSLocalizedString("Mistrusted",
            comment: "Privacy status title"),
            NSLocalizedString("This message has a communication partner that has previously been marked as mistrusted.",
                comment: "Privacy status explanation"),
            NSLocalizedString("Re-establish the connection with your communication partner and try to complete another handshake.",
                comment: "Privacy status suggestion")),
        PEP_rating_fully_anonymous:
            (NSLocalizedString("Secure & Trusted",
                comment: "Privacy status title"),
                NSLocalizedString("This message is secure and trusted.",
                    comment: "Privacy status explanation"),
                NSLocalizedString("No action needed!",
                    comment: "Privacy status suggestion")),
        PEP_rating_trusted_and_anonymized:
            (NSLocalizedString("Secure & Trusted",
                comment: "Privacy status title"),
                NSLocalizedString("This message is secure and trusted.",
                    comment: "Privacy status explanation"),
                NSLocalizedString("No action needed!",
                    comment: "Privacy status suggestion")),
        PEP_rating_trusted:
            (NSLocalizedString("Secure & Trusted",
                comment: "Privacy status title"),
                NSLocalizedString("This message is secure and trusted.",
                    comment: "Privacy status explanation"),
                NSLocalizedString("No action needed!",
                    comment: "Privacy status suggestion")),
        PEP_rating_reliable:
            (NSLocalizedString("Secure",
                comment: "Privacy status title"),
                NSLocalizedString("This message is secure but you still need to verify the identity of your communication partner.",
                    comment: "Privacy status explanation"),
                NSLocalizedString("Complete a handshake with your communication partner. A handshake is needed only once per partner and will ensure secure and trusted communication.",
                    comment: "Privacy status suggestion")),
        PEP_rating_unreliable:
            (NSLocalizedString("Unreliable Security",
                comment: "Privacy status title"),
                NSLocalizedString("This message has unreliable protection",
                    comment: "Privacy status explanation"),
                NSLocalizedString("This message has no reliable encryption or no signature. Ask your communication partner to upgrade their encryption solution or install p≡p.",
                    comment: "Privacy status suggestion")),
        PEP_rating_unencrypted_for_some:
            (NSLocalizedString("Unsecure for Some",
                comment: "Privacy status title"),
                NSLocalizedString("This message is unsecure for some communication partners.",
                    comment: "Privacy status explanation"),
                NSLocalizedString("Make sure the privacy status for each communication partner listed is at least secure",
                    comment: "Privacy status suggestion")),
        PEP_rating_unencrypted:
            (NSLocalizedString("Unsecure",
                comment: "Privacy status title"),
                NSLocalizedString("This message is unsecure.",
                    comment: "Privacy status explanation"),
                NSLocalizedString("Please ask your communication partner to use an encryption solution or install p≡p.",
                    comment: "Privacy status suggestion")),
        PEP_rating_have_no_key:
            (NSLocalizedString("Cannot Decrypt",
                comment: "Privacy status title"),
                NSLocalizedString("This message cannot be decrypted because the key is not available.",
                    comment: "Privacy status explanation"),
                NSLocalizedString("If this message was addressed to you, please inform the sender that you don't have the key.",
                    comment: "Privacy status suggestion")),
        PEP_rating_cannot_decrypt:
            (NSLocalizedString("Cannot Decrypt",
                comment: "Privacy status title"),
                NSLocalizedString("This message cannot be decrypted.",
                    comment: "Privacy status explanation"),
                NSLocalizedString("If this message was addressed to you, please inform the sender that you don't have the key.",
                    comment: "Privacy status suggestion")),
        PEP_rating_undefined:
            (NSLocalizedString("Unknown",
                comment: "Privacy status title"),
                NSLocalizedString("This message does not contain enough information to determine if it is secure.",
                    comment: "Privacy status explanation"),
                NSLocalizedString("Please add the necessary information.",
                    comment: "Privacy status suggestion"))]

open class PEPUtil {
    static let comp = "PEPUtil"

    /**
     Content type for MIME multipart/alternative.
     */
    open static let kMimeTypeMultipartAlternative = "multipart/alternative"

    fileprivate static let homeUrl = URL(fileURLWithPath:
        ProcessInfo.processInfo.environment["HOME"]!)
    fileprivate static let pEpManagementDbUrl =
        homeUrl.appendingPathComponent(".pEp_management.db")
    fileprivate static let systemDbUrl = homeUrl.appendingPathComponent("system.db")
    fileprivate static let gnupgUrl = homeUrl.appendingPathComponent(".gnupg")
    fileprivate static let gnupgSecringUrl = gnupgUrl.appendingPathComponent("secring.gpg")
    fileprivate static let gnupgPubringUrl = gnupgUrl.appendingPathComponent("pubring.gpg")
    
    // Provide filepath URLs as public dictionary.
    open static let pEpUrls: [String:URL] = [
        "home": homeUrl,
        "pEpManagementDb": pEpManagementDbUrl,
        "systemDb": systemDbUrl,
        "gnupg": gnupgUrl,
        "gnupgSecring": gnupgSecringUrl,
        "gnupgPubring": gnupgPubringUrl]
    
    // Delete pEp working data.
    open static func pEpClean() -> Bool {
        let pEpItemsToDelete: [String] = ["pEpManagementDb", "gnupg", "systemDb"]
        var error: NSError?
        
        for key in pEpItemsToDelete {
            let fileManager: FileManager = FileManager.default
            let itemToDelete: URL = pEpUrls[key]!
            if (itemToDelete as NSURL).checkResourceIsReachableAndReturnError(&error) {
                do {
                    try fileManager.removeItem(at: itemToDelete)
                }
                catch {
                    return false
                }
            }
        }
        return true
    }

    open static func identityFromAccount(_ account: Account,
                                           isMyself: Bool = true) -> NSMutableDictionary {
        let dict: NSMutableDictionary = [:]
        dict[kPepUsername] = account.nameOfTheUser
        dict[kPepAddress] = account.email
        dict[kPepIsMe] = isMyself
        return dict
    }

    /**
     Kicks off myself in the background, optionally notifies via block of termination/success.
     */
    open static func myselfFromAccount(_ account: Account, queue: OperationQueue,
                                         block: ((_ identity: NSDictionary) -> Void)? = nil) {
        let op = PEPMyselfOperation.init(account: account)
        op.completionBlock = {
            if let bl = block {
                bl(op.identity)
            }
        }
        queue.addOperation(op)
    }

    /**
     Converts an Contact (possibly from core data) to a pEp contact.
     - Parameter contact: The core data contact object.
     - Returns: An `PEPContact` contact for pEp.
     */
    open static func pepContact(_ contact: IContact) -> PEPContact {
        var dict = PEPContact()
        if let name = contact.name {
            dict[kPepUsername] = name as NSObject
        } else {
            dict[kPepUsername] = contact.email.namePartOfEmail() as NSObject
        }
        dict[kPepAddress] = contact.email as NSObject
        if contact.isMySelf.boolValue {
            dict[kPepIsMe] = contact.isMySelf
        }

        if let pepUserID = contact.pepUserID {
            dict[kPepUserID] = pepUserID as NSObject
        } else {
            // Only use an address book ID if this contact has no pEp ID
            if let addressBookID = contact.addressBookID {
                dict[kPepUserID] = String(describing: addressBookID) as NSObject
            }
        }
        return dict
    }

    /**
     Creates pEp contact from name and address. Useful for tests where you don't want
     more data filled in.
     */
    open static func pepContactFromEmail(_ email: String, name: String) -> PEPContact {
        var contact = PEPContact()
        contact[kPepAddress] = email as AnyObject
        contact[kPepUsername] = name as AnyObject
        return contact
    }

    /**
     Converts a core data attachment to a pEp attachment.
     - Parameter contact: The core data attachment object.
     - Returns: An `NSMutableDictionary` attachment for pEp.
     */
    open static func pepAttachment(_ attachment: Attachment) -> NSMutableDictionary {
        let dict: NSMutableDictionary = [:]

        if let filename = attachment.filename {
            dict[kPepMimeFilename] = filename
        }
        if let contentType = attachment.contentType {
            dict[kPepMimeType] = contentType
        }
        dict[kPepMimeData] = attachment.data

        return dict
    }

    /**
     Converts a core data message into the format required by pEp.
     - Parameter message: The core data message to convert
     - Returns: An object (`NSMutableDictionary`) suitable for processing with pEp.
     */
    open static func pepMail(_ message: Message, outgoing: Bool = true) -> PEPMail {
        var dict = PEPMail()

        if let subject = message.subject {
            dict[kPepShortMessage] = subject as AnyObject
        }

        dict[kPepTo] = NSArray.init(array: message.to.map() { return pepContact($0 as! IContact) })
        dict[kPepCC] = NSArray.init(array: message.cc.map() { return pepContact($0 as! IContact) })
        dict[kPepBCC] = NSArray.init(array: message.bcc.map() {
            return pepContact($0 as! IContact)
        })

        if let longMessage = message.longMessage {
            dict[kPepLongMessage] = longMessage as AnyObject
        }
        if let longMessageFormatted = message.longMessageFormatted {
            dict[kPepLongMessageFormatted] = longMessageFormatted as AnyObject
        }
        if let from = message.from {
            dict[kPepFrom]  = self.pepContact(from) as AnyObject
        }
        if let messageID = message.messageID {
            dict[kPepID] = messageID as AnyObject
        }
        dict[kPepOutgoing] = NSNumber.init(booleanLiteral: outgoing)

        dict[kPepAttachments] = NSArray.init(array: message.attachments.map() {
            return pepAttachment($0 as! Attachment)
        })

        var refs = [String]()
        for ref in message.references {
            refs.append((ref as! MessageReference).messageID)
        }
        if refs.count > 0 {
            dict[kPepReferences] = refs as AnyObject
        }

        return dict as PEPMail
    }

    open static func insertPepContact(_ pepContact: PEPContact, intoModel: ICdModel) -> Contact {
        let contact = intoModel.insertOrUpdateContactEmail(
            pepContact[kPepAddress] as! String,
            name: pepContact[kPepUsername] as? String)
        if let isMySelf = pepContact[kPepIsMe] as? Bool {
            contact.isMySelf = NSNumber(value: isMySelf)
        }

        // The only case where the kPepUserID is already set, should
        // be as a result of mySelf().
        if let pepUserID = pepContact[kPepUserID] as? String {
            contact.pepUserID = pepUserID
        }
        // If there is no pEp ID yet, try to use an addressbook ID
        if contact.pepUserID == nil {
            if let abID = contact.addressBookID?.int32Value {
                contact.pepUserID = String(abID)
            }
        }
        return contact
    }

    /**
     For a PEPMail, checks whether it is PGP/MIME encrypted.
     */
    open static func isProbablyPGPMimePepMail(_ message: PEPMail) -> Bool {
        guard let attachments = message[kPepAttachments] as? NSArray else {
            return false
        }

        var foundAttachmentPGPEncrypted = false
        for atch in attachments {
            guard let at = atch as? NSDictionary else {
                continue
            }
            guard let filename = at[kPepMimeType] as? String else {
                continue
            }
            if filename.lowercased() == Constants.contentTypePGPEncrypted {
                foundAttachmentPGPEncrypted = true
                break
            }
        }
        return foundAttachmentPGPEncrypted
    }

    /**
     Converts a pEp contact dict to a pantomime address.
     */
    open static func pantomimeContactFromPepContact(_ contact: PEPContact) -> CWInternetAddress {
        let address = CWInternetAddress.init()
        if let email = contact[kPepAddress] as? String {
            address.setAddress(email)
        }
        if let name = contact[kPepUsername] as? String {
            address.setPersonal(name)
        }
        return address
    }

    /**
     Converts a list of pEp contacts of a given receiver type to a list of pantomime recipients.
     */
    open static func makePantomimeRecipientsFromPepContacts(_ pepContacts: [PEPContact],
                                      recipientType: PantomimeRecipientType)
        -> [CWInternetAddress] {
            var addresses: [CWInternetAddress] = []
            for c in pepContacts {
                let address = pantomimeContactFromPepContact(c)
                address.setType(recipientType)
                addresses.append(address)
            }
            return addresses
    }

    open static func addPepContacts(_ recipients: [PEPContact], toPantomimeMessage: CWIMAPMessage,
                                      recipientType: PantomimeRecipientType) {
        let addresses = makePantomimeRecipientsFromPepContacts(
            recipients, recipientType: recipientType)
        for a in addresses {
            toPantomimeMessage.addRecipient(a)
        }
    }

    /**
     Converts a given `Message` into the equivalent `CWIMAPMessage`.
     */
    open static func pantomimeMailFromMessage(_ message: Message) -> CWIMAPMessage {
        return pantomimeMailFromPep(pepMail(message))
    }

    /**
     Converts a given `PEPMail` into the equivalent `CWIMAPMessage`.
     See https://tools.ietf.org/html/rfc2822 for a better understanding of some fields.
     */
    open static func pantomimeMailFromPep(_ pepMail: PEPMail) -> CWIMAPMessage {
        if let rawMessageData = pepMail[kPepRawMessage] as? Data {
            let message = CWIMAPMessage.init(data: rawMessageData)
            return message
        }

        let message = CWIMAPMessage.init()

        if let from = pepMail[kPepFrom] as? PEPContact {
            let address = pantomimeContactFromPepContact(from)
            message.setFrom(address)
        }

        if let recipients = pepMail[kPepTo] as? NSArray {
            addPepContacts(recipients as! [PEPContact], toPantomimeMessage: message,
                          recipientType: .toRecipient)
        }
        if let recipients = pepMail[kPepCC] as? NSArray {
            addPepContacts(recipients as! [PEPContact], toPantomimeMessage: message,
                          recipientType: .ccRecipient)
        }
        if let recipients = pepMail[kPepBCC] as? NSArray {
            addPepContacts(recipients as! [PEPContact], toPantomimeMessage: message,
                          recipientType: .bccRecipient)
        }
        if let messageID = pepMail[kPepID] as? String {
            message.setMessageID(messageID)
        }
        if let shortMsg = pepMail[kPepShortMessage] as? String {
            message.setSubject(shortMsg)
        }

        // Go over all references and inReplyTo, and add all the uniques
        // as references, with the inReplyTo last
        // (https://cr.yp.to/immhf/thread.html)
        let allRefsAdded = NSMutableOrderedSet()
        if let refs = pepMail[kPepReferences] as? [AnyObject] {
            for ref in refs {
                allRefsAdded.add(ref)
            }
        }
        if let inReplyTos = pepMail[kPepInReplyTo] as? [AnyObject] {
            for inReplyTo in inReplyTos {
                allRefsAdded.add(inReplyTo)
            }
        }
        message.setReferences(allRefsAdded.array)

        // deal with MIME type

        let attachmentDictsOpt = pepMail[kPepAttachments] as? NSArray
        if !MiscUtil.isNilOrEmptyNSArray(attachmentDictsOpt) {
            let encrypted = isProbablyPGPMimePepMail(pepMail)

            // Create multipart mail
            let multiPart = CWMIMEMultipart.init()
            if encrypted {
                message.setContentType(Constants.contentTypeMultipartEncrypted)
                message.setParameter(Constants.protocolPGPEncrypted, forKey: "protocol")
            } else {
                message.setContentType(Constants.contentTypeMultipartMixed)
            }
            message.setContent(multiPart)

            if !encrypted {
                let bodyPart = bodyPartFromPepMail(pepMail)
                multiPart.add(bodyPart)
            }

            if let attachmentDicts = attachmentDictsOpt {
                for attachmentDict in attachmentDicts {
                    guard let at = attachmentDict as? [String:NSObject]  else {
                        continue
                    }
                    let part = CWPart.init()
                    part.setContentType(at[kPepMimeType] as? String)
                    part.setContent(at[kPepMimeData])
                    part.setFilename(at[kPepMimeFilename] as? String)
                    multiPart.add(part)
                }
            }
        } else {
            if let body = bodyPartFromPepMail(pepMail) {
                message.setContent(body.content())
                message.setContentType(body.contentType())
            }
        }

        return message
    }

    /**
     Extracts the body of a pEp mail as a pantomime part object.
     - Returns: Either a single CWPart,
     if there is only one text content (either pure text or HTML),
     or a "multipart/alternative" if there is both text and HTML,
     or nil.
     */
    static func bodyPartFromPepMail(_ pepMail: PEPMail) -> CWPart? {
        let bodyParts = bodyPartsFromPepMail(pepMail)
        if bodyParts.count == 1 {
            return bodyParts[0]
        } else if bodyParts.count > 1 {
            let partAlt = CWPart.init()
            partAlt.setContentType(Constants.contentTypeMultipartAlternative)
            let partMulti = CWMIMEMultipart.init()
            for part in bodyParts {
                partMulti.add(part)
            }
            partAlt.setContent(partMulti)
            return partAlt
        }
        return nil
    }

    /**
     Builds an optional pantomime part object from an optional text,
     with the given content type.
     Useful for creating text/HTML parts.
     */
    static func makePartFromText(_ text: String?, contentType: String) -> CWPart? {
        if let t = text {
            let part = CWPart.init()
            part.setContentType(contentType)
            part.setContent(t.data(using: String.Encoding.utf8) as NSObject?)
            part.setCharset("UTF-8")
            return part
        }
        return nil
    }

    /**
     Extracts text content from a pEp mail as a list of pantomime part object.
     - Returns: A list of pantomime parts. This list can have 0, 1 or 2 elements.
     */
    static func bodyPartsFromPepMail(_ pepMail: PEPMail) -> [CWPart] {
        var parts: [CWPart] = []

        if let part = makePartFromText(pepMail[kPepLongMessage] as? String,
                                       contentType: Constants.contentTypeText) {
            parts.append(part)
        }
        if let part = makePartFromText(pepMail[kPepLongMessageFormatted] as? String,
                                       contentType: Constants.contentTypeHtml) {
            parts.append(part)
        }

        return parts
    }

    open static func colorRatingForContact(_ contact: IContact,
                                             session: PEPSession? = nil) -> PEP_rating {
        let theSession = useOrCreateSession(session)
        let pepC = pepContact(contact)
        let color = theSession.identityColor(pepC)
        return color
    }

    open static func privacyColorForContact(_ contact: Contact,
                                              session: PEPSession? = nil) -> PEP_color {
        let theSession = useOrCreateSession(session)
        let pepC = pepContact(contact)
        let color = theSession.identityColor(pepC)
        return colorFromPepRating(color)
    }

    open static func colorFromPepRating(_ pepColorRating: PEP_rating) -> PEP_color {
        return color_from_rating(pepColorRating)
    }

    open static func colorRatingFromInt(_ i: Int?) -> PEP_rating? {
        guard let theInt = i else {
            return nil
        }
        let int32 = Int32(theInt)
        return pepColorDictionary[int32]
    }

    open static func pepTitleFromColor(_ pepColorRating: PEP_rating) -> String? {
        if let (title, _, _) = pepPricacyStatusTranslations[pepColorRating] {
            return title
        }
        Log.warnComponent(comp, "No privacy title for color rating \(pepColorRating)")
        return nil
    }

    open static func pepExplanationFromColor(_ pepColorRating: PEP_rating) -> String? {
        if let (_, explanation, _) = pepPricacyStatusTranslations[pepColorRating] {
            return explanation
        }
        Log.warnComponent(comp, "No privacy explanation for color rating \(pepColorRating)")
        return nil
    }

    open static func pepSuggestionFromColor(_ pepColorRating: PEP_rating) -> String? {
        if let (_, _, suggestion) = pepPricacyStatusTranslations[pepColorRating] {
            return suggestion
        }
        Log.warnComponent(comp, "No privacy suggestion for color rating \(pepColorRating)")
        return nil
    }

    open static func sessionOrReuse(_ session: PEPSession?) -> PEPSession {
        if session == nil {
            return PEPSession.init()
        }
        return session!
    }

    /**
     - Returns: The short trustwords for a fingerprint as one single String.
     */
    open static func shortTrustwordsForFpr(_ fpr: String, language: String,
                                             session: PEPSession?) -> String {
        let words = sessionOrReuse(session).trustwords(
            fpr, forLanguage: language, shortened: true) as! [String]
        return words.joined(separator: " ")
    }

    open static func trustwordsForIdentity1(_ identity1: PEPContact,
                                              identity2: PEPContact,
                                              language: String,
                                              session: PEPSession?) -> String? {
        let theSession = sessionOrReuse(session)
        let dict1 = NSMutableDictionary.init(dictionary: identity1)
        let dict2 = NSMutableDictionary.init(dictionary: identity2)
        theSession.updateIdentity(dict1)
        theSession.updateIdentity(dict2)

        guard let fpr1 = dict1[kPepFingerprint] as? String else {
            return nil
        }
        guard let fpr2 = dict2[kPepFingerprint] as? String else {
            return nil
        }

        let trustwords1 = shortTrustwordsForFpr(fpr1, language: language, session: session)
        let trustwords2 = shortTrustwordsForFpr(fpr2, language: language, session: session)

        let comp = fpr1.compare(fpr2)
        switch comp {
        case .orderedAscending, .orderedSame:
            return "\(trustwords1) \(trustwords2)"
        default:
            return "\(trustwords2) \(trustwords1)"
        }
    }

    /**
     Overwrites an existing message with properties from the pEp mail dictionary.
     Used after a mail has been decrypted.
     That means that for now, recipients are not overwritten, because they don't
     change after decrypt (until the engine handles the communication layer too).
     What can change is body text, subject, attachments.
     Optional fields (`kPepOptFields`) might have to be taken care of later.
     Caller is responsible for saving the model!
     */
    open static func updateDecryptedMessage(_ message: Message, fromPepMail: PEPMail,
                                              pepColorRating: PEP_rating?, model: ICdModel) {
        if let color = pepColorRating {
            message.pepColorRating = NSNumber.init(value: color.rawValue as Int32)
        } else {
            message.pepColorRating = nil
        }
        message.subject = fromPepMail[kPepShortMessage] as? String
        message.longMessage = fromPepMail[kPepLongMessage] as? String
        message.longMessageFormatted = fromPepMail[kPepLongMessageFormatted] as? String

        // Remove existing attachments, this doesn't happen automatically with core data
        model.deleteAttachmentsFromMessage(message)

        var attachments = [AnyObject]()
        if let attachmentDicts = fromPepMail[kPepAttachments] as? NSArray {
            for atDict in attachmentDicts {
                guard let at = atDict as? NSDictionary else {
                    continue
                }
                guard let data = at[kPepMimeData] as? Data else {
                    continue
                }
                let attach = model.insertAttachmentWithContentType(
                    at[kPepMimeType] as? String,
                    filename: at[kPepMimeFilename] as? String,
                    data: data)
                attachments.append(attach)
            }
        }
        message.attachments = NSOrderedSet.init(array: attachments)
    }

    /**
     - Returns: An NSOrderedSet that contains all elements of `array`. If `array` is nil,
     the ordered set is empty.
     */
    open static func orderedContactSetFromPepContactArray(
        _ array: NSArray?, model: ICdModel) -> NSOrderedSet {
        if let ar = array {
            let contacts: [AnyObject] = ar.map() {
                let contact = insertPepContact($0 as! PEPContact, intoModel: model)
                return contact
            }
            return NSOrderedSet.init(array: contacts)
        }
        return NSOrderedSet()
    }

    /**
     Completely updates a freshly inserted message from a pEp mail dictionary. Useful for tests.
     Caller is responsible for saving the model!
     */
    open static func updateWholeMessage(_ message: Message, fromPepMail: PEPMail, model: ICdModel) {
        updateDecryptedMessage(message, fromPepMail: fromPepMail, pepColorRating: nil,
                      model: model)
        message.to = orderedContactSetFromPepContactArray(
            fromPepMail[kPepTo] as? NSArray, model: model)
        message.cc = orderedContactSetFromPepContactArray(
            fromPepMail[kPepCC] as? NSArray, model: model)
        message.bcc = orderedContactSetFromPepContactArray(
            fromPepMail[kPepBCC] as? NSArray, model: model)

        message.longMessage = fromPepMail[kPepLongMessage] as? String
        message.longMessageFormatted = fromPepMail[kPepLongMessageFormatted] as? String

        // TODO: Map the following:
        // kPepSent, kPepReceived, kPepReplyTo, kPepInReplyTo, kPepReferences, kPepOptFields
    }

    /**
     - Returns: A non-optional session from an optional one. If the input session is nil,
     one is created on the spot.
     */
    open static func useOrCreateSession(_ session: PEPSession?) -> PEPSession {
        if let s = session {
            return s
        }
        return PEPSession.init()
    }

    /**
     - Returns: The fingerprint for a contact.
     */
    open static func fingprprintForContact(
        _ contact: Contact, session: PEPSession? = nil) -> String? {
        let pepC = pepContact(contact)
        return fingprprintForPepContact(pepC)
    }

    /**
     - Returns: The fingerprint for a pEp contact.
     */
    open static func fingprprintForPepContact(
        _ contact: PEPContact, session: PEPSession? = nil) -> String? {
        let pepDict = NSMutableDictionary.init(dictionary: contact)

        let theSession = useOrCreateSession(session)
        theSession.updateIdentity(pepDict)

        return pepDict[kPepFingerprint] as? String
    }

    /**
     Trust that contact (yellow to green).
     */
    open static func trustContact(_ contact: Contact, session: PEPSession? = nil) {
        let theSession = useOrCreateSession(session)
        let pepC = NSMutableDictionary.init(dictionary: pepContact(contact))
        theSession.updateIdentity(pepC)
        theSession.trustPersonalKey(pepC)
    }

    /**
     Mistrust the identity (yellow to red)
     */
    open static func mistrustContact(_ contact: Contact, session: PEPSession? = nil) {
        let theSession = useOrCreateSession(session)
        let pepC = NSMutableDictionary.init(dictionary: pepContact(contact))
        theSession.updateIdentity(pepC)
        theSession.keyMistrusted(pepC)
    }

    /**
     Resets the trust for the given contact. Use both for trusting again after
     mistrusting a key, and for mistrusting a key after you have first trusted it.
     */
    open static func resetTrustForContact(_ contact: Contact, session: PEPSession? = nil) {
        let theSession = useOrCreateSession(session)
        let pepC = NSMutableDictionary.init(dictionary: pepContact(contact))
        theSession.updateIdentity(pepC)
        theSession.keyResetTrust(pepC)
    }

    /**
     Checks the given pEp status and the given encrypted mail for errors and
     logs them.
     - Returns: A tuple of the encrypted mail and an error. Both can be nil.
     */
    static func checkPepStatus( _ comp: String, status: PEP_STATUS,
                                encryptedMail: NSDictionary?) -> (NSDictionary?, NSError?) {
        if encryptedMail != nil && status == PEP_UNENCRYPTED {
            // Don't interpret that as an error
            return (encryptedMail, nil)
        }
        if encryptedMail == nil || status != PEP_STATUS_OK {
            let error = Constants.errorEncryption(comp, status: status)
            Log.errorComponent(comp, error: Constants.errorInvalidParameter(
                comp, errorMessage: "Could not encrypt message, pEp status \(status)"))
            return (encryptedMail, error)
        }
        return (encryptedMail, nil)
    }
}
