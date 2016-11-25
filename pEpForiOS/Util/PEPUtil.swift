//
//  PEPUtil.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

/**
 Simple `Hashable` implementation so PEP_rating can be put into dictionaries.
 */
extension PEP_rating: Hashable {
    public var hashValue: Int {
        return Int(rawValue)
    }
}

open class PEPUtil {
    static let comp = "PEPUtil"
    
    /**
     Default pEpRating value when there's none.
     */
    public static let pEpRatingNone = Int16.min

    /**
     All privacy status strings, i18n ready.
     */
    static let pEpRatingTranslations: [PEP_rating: (String, String, String)] =
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

    /**
     Provide filepath URLs as public dictionary.
     */
    open static let pEpUrls: [String:URL] = [
        "home": homeUrl,
        "pEpManagementDb": pEpManagementDbUrl,
        "systemDb": systemDbUrl,
        "gnupg": gnupgUrl,
        "gnupgSecring": gnupgSecringUrl,
        "gnupgPubring": gnupgPubringUrl]
    
    /** Delete pEp working data. */
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

    open static func identity(account: CdAccount) -> PEPIdentity {
        if let id = account.identity {
            return pEp(cdIdentity: id)
        }
        return [:]
    }

    /**
     Kicks off myself in the background, optionally notifies via block of termination/success.
     */
    open static func myself(account: Account, queue: OperationQueue,
                            block: ((_ identity: NSDictionary) -> Void)? = nil) {
        let op = PEPMyselfOperation(account: account)
        op.completionBlock = {
            block?(op.identity)
        }
        queue.addOperation(op)
    }

    open static func pEp(identity: Identity) -> PEPIdentity {
        var contact = PEPIdentity()
        contact[kPepAddress] = identity.address as AnyObject
        contact[kPepUsername] = identity.userName as AnyObject
        contact[kPepIsMe] = identity.isMySelf as AnyObject
        return contact
    }

    /**
     Converts a `CdIdentity` to a pEp contact.
     - Parameter cdIdentity: The core data contact object.
     - Returns: An `PEPIdentity` contact for pEp.
     */
    open static func pEp(cdIdentity: CdIdentity) -> PEPIdentity {
        var dict = PEPIdentity()
        if let name = cdIdentity.userName{
            dict[kPepUsername] = name as NSObject
        } else {
            dict[kPepUsername] = cdIdentity.address as AnyObject
        }
        dict[kPepAddress] = cdIdentity.address as AnyObject
        dict[kPepIsMe] = cdIdentity.isMySelf
        return dict
    }

    /**
     Creates pEp contact just from name and address.
     */
    open static func pEpIdentity(email: String, name: String) -> PEPIdentity {
        var identity = PEPIdentity()
        identity[kPepAddress] = email as AnyObject
        identity[kPepUsername] = name as AnyObject
        identity[kPepIsMe] = NSNumber(booleanLiteral: false)
        return identity
    }

    open static func pEpOptional(identity: Identity?) -> PEPIdentity? {
        guard let id = identity else {
            return nil
        }
        return pEp(identity: id)
    }

    /**
     Converts a core data attachment to a pEp attachment.
     - Parameter contact: The core data attachment object.
     - Returns: An `NSMutableDictionary` attachment for pEp.
     */
    open static func pepAttachment(_ attachment: CdAttachment) -> NSMutableDictionary {
        let dict: NSMutableDictionary = [:]

        dict[kPepMimeFilename] = attachment.fileName
        dict[kPepMimeType] = attachment.mimeType
        dict[kPepMimeData] = attachment.data

        return dict
    }

    open static func pEp(attachment: Attachment) -> [String: AnyObject] {
        var dict = [String: AnyObject]()

        dict[kPepMimeFilename] = attachment.fileName as AnyObject
        dict[kPepMimeType] = attachment.mimeType as AnyObject
        dict[kPepMimeData] = attachment.data as AnyObject

        return dict
    }

    open static func pEp(message: Message, outgoing: Bool = true) -> PEPMessage {
        var dict = PEPMessage()

        dict[kPepShortMessage] = message.shortMessage as AnyObject

        dict[kPepTo] = NSArray.init(array: message.to.map() { return pEp(identity: $0) })
        dict[kPepCC] = NSArray.init(array: message.cc.map() { return pEp(identity: $0) })
        dict[kPepBCC] = NSArray.init(array: message.bcc.map() { return pEp(identity: $0) })

        dict[kPepFrom]  = pEpOptional(identity: message.from) as AnyObject
        dict[kPepID] = message.messageID as AnyObject
        dict[kPepOutgoing] = outgoing as AnyObject?

        dict[kPepAttachments] = NSArray.init(array: message.attachments.map() {
            return pEp(attachment: $0)
        })

        dict[kPepReferences] = message.references as AnyObject

        return dict
    }

    /**
     Converts a core data message into the format required by pEp.
     - Parameter message: The core data message to convert
     - Returns: An object (`NSMutableDictionary`) suitable for processing with pEp.
     */
    open static func pepMail(_ message: CdMessage, outgoing: Bool = true) -> PEPMessage {
        var dict = PEPMessage()

        if let subject = message.shortMessage {
            dict[kPepShortMessage] = subject as AnyObject
        }

        /* XXX: Refactor:
        dict[kPepTo] = NSArray.init(array: message.to.map() { return pEp(identity: $0 as! CdIdentity) })
        dict[kPepCC] = NSArray.init(array: message.cc.map() { return pEp(identity: $0 as! CdIdentity) })
        dict[kPepBCC] = NSArray.init(array: message.bcc.map() {
            return pEp(identity: $0 as! CdIdentity)
        })
        */

        if let longMessage = message.longMessage {
            dict[kPepLongMessage] = longMessage as AnyObject
        }
        if let longMessageFormatted = message.longMessageFormatted {
            dict[kPepLongMessageFormatted] = longMessageFormatted as AnyObject
        }
        if let from = message.from {
            dict[kPepFrom]  = self.pEp(cdIdentity: from) as AnyObject
        }
        if let messageID = message.messageID {
            dict[kPepID] = messageID as AnyObject
        }
        dict[kPepOutgoing] = NSNumber.init(booleanLiteral: outgoing)

        /* XXX: Refactor:
        dict[kPepAttachments] = NSArray.init(array: message.attachments {
            return pepAttachment($0 as! CdAttachment)
        })
        */

        var refs = [String]()
        for ref in message.references! {
            refs.append((ref as! CdMessageReference).reference!)
        }
        if refs.count > 0 {
            dict[kPepReferences] = refs as AnyObject
        }

        return dict as PEPMessage
    }

    open static func pEp(mail: CdMessage, outgoing: Bool = true) -> PEPMessage {
        var dict = PEPMessage()

        if let subject = mail.shortMessage {
            dict[kPepShortMessage] = subject as AnyObject
        }

        dict[kPepTo] = NSArray(array: mail.to!.map() { return pEp(cdIdentity: $0 as! CdIdentity) })
        dict[kPepCC] = NSArray(array: mail.cc!.map() { return pEp(cdIdentity: $0 as! CdIdentity) })
        dict[kPepBCC] = NSArray(array: mail.bcc!.map() { return pEp(cdIdentity: $0 as! CdIdentity)
        })

        if let longMessage = mail.longMessage {
            dict[kPepLongMessage] = longMessage as AnyObject
        }
        if let longMessageFormatted = mail.longMessageFormatted {
            dict[kPepLongMessageFormatted] = longMessageFormatted as AnyObject
        }
        if let from = mail.from {
            dict[kPepFrom]  = self.pEp(cdIdentity: from) as AnyObject
        }
        if let messageID = mail.uuid {
            dict[kPepID] = messageID as AnyObject
        }
        dict[kPepOutgoing] = NSNumber(booleanLiteral: outgoing)

        dict[kPepAttachments] = NSArray(array: mail.attachments!.map() {
            return pepAttachment($0 as! CdAttachment)
        })

        var refs = [String]()
        for ref in mail.references! {
            refs.append((ref as! CdMessageReference).reference!)
        }
        if refs.count > 0 {
            dict[kPepReferences] = refs as AnyObject
        }
        
        return dict as PEPMessage
    }

    /**
     For a PEPMessage, checks whether it is PGP/MIME encrypted.
     */
    open static func isProbablyPGPMimePepMail(_ message: PEPMessage) -> Bool {
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
    open static func pantomimeContactFromPepContact(_ contact: PEPIdentity) -> CWInternetAddress {
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
    open static func makePantomimeRecipientsFromPepContacts(_ pepContacts: [PEPIdentity],
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

    open static func addPepContacts(_ recipients: [PEPIdentity], toPantomimeMessage: CWIMAPMessage,
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
    open static func pantomimeMailFromMessage(_ message: CdMessage) -> CWIMAPMessage {
        return pantomimeMailFromPep(pepMail(message))
    }

    open static func pantomimeMail(message: Message) -> CWIMAPMessage {
        return pantomimeMailFromPep(pEp(message: message))
    }

    /**
     Converts a given `PEPMessage` into the equivalent `CWIMAPMessage`.
     See https://tools.ietf.org/html/rfc2822 for a better understanding of some fields.
     */
    open static func pantomimeMailFromPep(_ pepMail: PEPMessage) -> CWIMAPMessage {
        if let rawMessageData = pepMail[kPepRawMessage] as? Data {
            let message = CWIMAPMessage.init(data: rawMessageData)
            return message
        }

        let message = CWIMAPMessage.init()

        if let from = pepMail[kPepFrom] as? PEPIdentity {
            let address = pantomimeContactFromPepContact(from)
            message.setFrom(address)
        }

        if let recipients = pepMail[kPepTo] as? NSArray {
            addPepContacts(recipients as! [PEPIdentity], toPantomimeMessage: message,
                          recipientType: .toRecipient)
        }
        if let recipients = pepMail[kPepCC] as? NSArray {
            addPepContacts(recipients as! [PEPIdentity], toPantomimeMessage: message,
                          recipientType: .ccRecipient)
        }
        if let recipients = pepMail[kPepBCC] as? NSArray {
            addPepContacts(recipients as! [PEPIdentity], toPantomimeMessage: message,
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
                if let bodyPart = bodyPartFromPepMail(pepMail) {
                    multiPart.add(bodyPart)
                }
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
    static func bodyPartFromPepMail(_ pepMail: PEPMessage) -> CWPart? {
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
    static func bodyPartsFromPepMail(_ pepMail: PEPMessage) -> [CWPart] {
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

    open static func colorRatingForContact(_ contact: CdIdentity,
                                             session: PEPSession? = nil) -> PEP_rating {
        let theSession = useOrCreateSession(session)
        let pepC = pEp(cdIdentity: contact)
        let color = theSession.identityColor(pepC)
        return color
    }

    open static func privacyColorForContact(_ contact: CdIdentity,
                                              session: PEPSession? = nil) -> PEP_color {
        let theSession = useOrCreateSession(session)
        let pepC = pEp(cdIdentity: contact)
        let color = theSession.identityColor(pepC)
        return pEpColorFromRating(color)
    }

    open static func pEpColor(identity: Identity,
                                  session: PEPSession? = nil) -> PEP_color {
        let theSession = useOrCreateSession(session)
        let pepC = pEp(identity: identity)
        let color = theSession.identityColor(pepC)
        return pEpColorFromRating(color)
    }

    open static func pEpColorFromRating(_ pepColorRating: PEP_rating) -> PEP_color {
        return color_from_rating(pepColorRating)
    }

    open static func pEpRatingFromInt(_ i: Int?) -> PEP_rating? {
        guard let theInt = i else {
            return nil
        }
        return PEP_rating.init(Int32(theInt))
    }

    open static func pEpTitleFromRating(_ pepColorRating: PEP_rating) -> String? {
        if let (title, _, _) = PEPUtil.pEpRatingTranslations[pepColorRating] {
            return title
        }
        Log.warn(component: comp, "No privacy title for color rating \(pepColorRating)")
        return nil
    }

    open static func pEpExplanationFromRating(_ pepColorRating: PEP_rating) -> String? {
        if let (_, explanation, _) = PEPUtil.pEpRatingTranslations[pepColorRating] {
            return explanation
        }
        Log.warn(component: comp, "No privacy explanation for color rating \(pepColorRating)")
        return nil
    }

    open static func pEpSuggestionFromRating(_ pepColorRating: PEP_rating) -> String? {
        if let (_, _, suggestion) = pEpRatingTranslations[pepColorRating] {
            return suggestion
        }
        Log.warn(component: comp, "No privacy suggestion for color rating \(pepColorRating)")
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

    open static func trustwords(identity1: PEPIdentity, identity2: PEPIdentity,
                                language: String, session: PEPSession?) -> String? {
        let theSession = sessionOrReuse(session)
        return theSession.getTrustwordsIdentity1(identity1, identity2: identity2,
                                                 language: language, full: true)
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
    open static func fingerPrintForContact(
        _ contact: CdIdentity, session: PEPSession? = nil) -> String? {
        let pepC = pEp(cdIdentity: contact)
        return fingerPrintForPepContact(pepC)
    }

    /**
     - Returns: The fingerprint for a pEp contact.
     */
    open static func fingerPrintForPepContact(
        _ contact: PEPIdentity, session: PEPSession? = nil) -> String? {
        let pepDict = NSMutableDictionary.init(dictionary: contact)

        let theSession = useOrCreateSession(session)
        theSession.updateIdentity(pepDict)

        return pepDict[kPepFingerprint] as? String
    }

    open static func fingerPrint(identity: Identity, session: PEPSession? = nil) -> String? {
        if let fpr = identity.fingerPrint {
            return fpr
        }

        let theSession = useOrCreateSession(session)
        let pEpID = pEp(identity: identity)
        let pEpDict = NSMutableDictionary.init(dictionary: pEpID)
        theSession.updateIdentity(pEpDict)
        return pEpDict[kPepFingerprint] as? String
    }

    /**
     Trust that contact (yellow to green).
     */
    open static func trustContact(_ contact: CdIdentity, session: PEPSession? = nil) {
        let theSession = useOrCreateSession(session)
        let pepC = NSMutableDictionary.init(dictionary: pEp(cdIdentity: contact))
        theSession.updateIdentity(pepC)
        theSession.trustPersonalKey(pepC)
    }

    /**
     Trust that contact (yellow to green).
     */
    open static func trust(identity: Identity, session: PEPSession? = nil) {
        let theSession = useOrCreateSession(session)
        let pepC = NSMutableDictionary.init(dictionary: pEp(identity: identity))
        theSession.updateIdentity(pepC)
        theSession.trustPersonalKey(pepC)
    }

    /**
     Mistrust the identity (yellow to red)
     */
    open static func mistrustContact(_ contact: CdIdentity, session: PEPSession? = nil) {
        let theSession = useOrCreateSession(session)
        let pepC = NSMutableDictionary.init(dictionary: pEp(cdIdentity: contact))
        theSession.updateIdentity(pepC)
        theSession.keyMistrusted(pepC)
    }

    /**
     Mistrust the identity (yellow to red)
     */
    open static func mistrust(identity: Identity, session: PEPSession? = nil) {
        let theSession = useOrCreateSession(session)
        let pepC = NSMutableDictionary.init(dictionary: pEp(identity: identity))
        theSession.updateIdentity(pepC)
        theSession.keyMistrusted(pepC)
    }

    /**
     Resets the trust for the given contact. Use both for trusting again after
     mistrusting a key, and for mistrusting a key after you have first trusted it.
     */
    open static func resetTrustForContact(_ contact: CdIdentity, session: PEPSession? = nil) {
        let theSession = useOrCreateSession(session)
        let pepC = NSMutableDictionary.init(dictionary: pEp(cdIdentity: contact))
        theSession.updateIdentity(pepC)
        theSession.keyResetTrust(pepC)
    }

    /**
     Resets the trust for the given `Identity`. Use both for trusting again after
     mistrusting a key, and for mistrusting a key after you have first trusted it.
     */
    open static func resetTrust(identity: Identity, session: PEPSession? = nil) {
        let theSession = useOrCreateSession(session)
        let pepC = NSMutableDictionary.init(dictionary: pEp(identity: identity))
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
            Log.error(component: comp, error: Constants.errorInvalidParameter(
                comp, errorMessage: "Could not encrypt message, pEp status \(status)"))
            return (encryptedMail, error)
        }
        return (encryptedMail, nil)
    }
}
