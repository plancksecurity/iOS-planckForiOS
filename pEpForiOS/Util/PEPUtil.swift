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

public struct TrustwordsLanguage {
    /** The language code that you have to feed to the trustwords functions */
    public let languageCode: String

    /** The name of the language, for display to the user */
    public let languageName: String
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
            (NSLocalizedString("Broken",
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

    /** Delete pEp working data. */
    open static func pEpClean() -> Bool {
        let homeURL = PEPiOSAdapter.homeURL() as URL

        let pEpItemsToDelete: [URL] = [
            homeURL.appendingPathComponent(".pEp_management.db"),
            homeURL.appendingPathComponent(".gnupg"),
            homeURL.appendingPathComponent("secring.gpg"),
            homeURL.appendingPathComponent("secring.gpg")]

        let fileManager: FileManager = FileManager.default
        for itemToDelete in pEpItemsToDelete {
            do {
                if try itemToDelete.checkResourceIsReachable() {
                    try fileManager.removeItem(at: itemToDelete)
                }
            }
            catch {
                continue
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

    open static func pEp(identity: Identity) -> PEPIdentity {
        var contact = PEPIdentity()
        contact[kPepAddress] = identity.address as AnyObject
        if let userN = identity.userName {
            contact[kPepUsername] = userN as AnyObject
        }
        if let userID = identity.userID {
            contact[kPepUserID] = userID as AnyObject
        }
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
        if let name = cdIdentity.userName {
            dict[kPepUsername] = name as NSObject
        }
        if let userID = cdIdentity.userID {
            dict[kPepUserID] = userID as NSObject
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
     Converts a `CdAttachment` into a pEp attachment.
     */
    open static func pEp(cdAttachment: CdAttachment) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [:]

        dict[kPepMimeFilename] = cdAttachment.fileName as NSString?
        dict[kPepMimeType] = cdAttachment.mimeType as NSString?
        dict[kPepMimeData] = cdAttachment.data

        return dict
    }

    /**
     Converts an `Attachment` into a pEp attachment.
     */
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

        dict[kPepTo] = NSArray(array: message.to.map() { return pEp(identity: $0) })
        dict[kPepCC] = NSArray(array: message.cc.map() { return pEp(identity: $0) })
        dict[kPepBCC] = NSArray(array: message.bcc.map() { return pEp(identity: $0) })

        dict[kPepFrom]  = pEpOptional(identity: message.from) as AnyObject
        dict[kPepID] = message.messageID as AnyObject
        dict[kPepOutgoing] = outgoing as AnyObject?

        dict[kPepAttachments] = NSArray(array: message.attachments.map() {
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
    open static func pEp(cdMessage: CdMessage, outgoing: Bool = true) -> PEPMessage {
        var dict = PEPMessage()

        if let sent = cdMessage.sent {
            dict[kPepSent] = sent
        }

        if let subject = cdMessage.shortMessage {
            dict[kPepShortMessage] = subject as AnyObject
        }

        dict[kPepTo] = NSArray(array: cdMessage.to!.map()
            { return pEp(cdIdentity: $0 as! CdIdentity) })
        dict[kPepCC] = NSArray(array: cdMessage.cc!.map()
            { return pEp(cdIdentity: $0 as! CdIdentity) })
        dict[kPepBCC] = NSArray(array: cdMessage.bcc!.map()
            { return pEp(cdIdentity: $0 as! CdIdentity) })

        if let longMessage = cdMessage.longMessage {
            dict[kPepLongMessage] = longMessage as AnyObject
        }
        if let longMessageFormatted = cdMessage.longMessageFormatted {
            dict[kPepLongMessageFormatted] = longMessageFormatted as AnyObject
        }
        if let from = cdMessage.from {
            dict[kPepFrom]  = self.pEp(cdIdentity: from) as AnyObject
        }
        if let messageID = cdMessage.uuid {
            dict[kPepID] = messageID as AnyObject
        }
        dict[kPepOutgoing] = NSNumber(booleanLiteral: outgoing)

        dict[kPepAttachments] = NSArray(array: cdMessage.attachments!.map() {
            return pEp(cdAttachment: $0 as! CdAttachment)
        })

        var refs = [String]()
        for ref in cdMessage.references! {
            refs.append((ref as! CdMessageReference).reference!)
        }

        if refs.count > 0 {
            dict[kPepReferences] = refs as AnyObject
        }

        if let l = refs.last {
            dict[kPepInReplyTo] = l as AnyObject
        }

        if let r = cdMessage.replyTo {
            dict[kPepReplyTo] = r.array as AnyObject
        }

        dict[kPepReplyTo] = NSArray(array: cdMessage.replyTo!.map()
            { return pEp(cdIdentity: $0 as! CdIdentity) })

        //dict[kPepOptFields] = NSArray(array: cdMessage.optionalFields!.array())

        return dict as PEPMessage
    }

    /**
     For a PEPMessage, checks whether it is probably PGP/MIME encrypted.
     */
    open static func isProbablyPGPMime(pEpMessage: PEPMessage) -> Bool {
        guard let attachments = pEpMessage[kPepAttachments] as? NSArray else {
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
     For a CdMessage, checks whether it is probably PGP/MIME encrypted.
     */
    open static func isProbablyPGPMime(cdMessage: CdMessage) -> Bool {
        return isProbablyPGPMime(pEpMessage: pEp(cdMessage: cdMessage))
    }

    /**
     Converts a pEp identity dict to a pantomime address.
     */
    open static func pantomime(pEpIdentity: PEPIdentity) -> CWInternetAddress {
        let address = CWInternetAddress()
        if let email = pEpIdentity[kPepAddress] as? String {
            address.setAddress(email)
        }
        if let name = pEpIdentity[kPepUsername] as? String {
            address.setPersonal(name)
        }
        return address
    }

    /**
     Converts a list of pEp identities of a given receiver type to a list of pantomime recipients.
     */
    open static func pantomime(pEpIdentities: [PEPIdentity], recipientType: PantomimeRecipientType)
        -> [CWInternetAddress] {
            var addresses: [CWInternetAddress] = []
            for c in pEpIdentities {
                let address = pantomime(pEpIdentity: c)
                address.setType(recipientType)
                addresses.append(address)
            }
            return addresses
    }

    open static func add(pEpIdentities: [PEPIdentity], toPantomimeMessage: CWIMAPMessage,
                         recipientType: PantomimeRecipientType) {
        let addresses = pantomime(
            pEpIdentities: pEpIdentities, recipientType: recipientType)
        for a in addresses {
            toPantomimeMessage.addRecipient(a)
        }
    }

    /**
     Converts a given `CdMessage` into the equivalent `CWIMAPMessage`.
     */
    open static func pantomime(cdMessage: CdMessage) -> CWIMAPMessage {
        return pantomime(pEpMessage: pEp(cdMessage: cdMessage))
    }

    /**
     Converts a given `Message` into the equivalent `CWIMAPMessage`.
     */
    open static func pantomime(message: Message) -> CWIMAPMessage {
        return pantomime(pEpMessage: pEp(message: message))
    }

    /**
     Converts a given `PEPMessage` into the equivalent `CWIMAPMessage`.
     See https://tools.ietf.org/html/rfc2822 for a better understanding of some fields.
     */
    open static func pantomime(pEpMessage: PEPMessage) -> CWIMAPMessage {
        if let rawMessageData = pEpMessage[kPepRawMessage] as? Data {
            let message = CWIMAPMessage(data: rawMessageData)
            return message
        }

        let message = CWIMAPMessage()

        if let from = pEpMessage[kPepFrom] as? PEPIdentity {
            let address = pantomime(pEpIdentity: from)
            message.setFrom(address)
        }

        if let recipients = pEpMessage[kPepTo] as? NSArray {
            add(pEpIdentities: recipients as! [PEPIdentity], toPantomimeMessage: message,
                recipientType: .toRecipient)
        }
        if let recipients = pEpMessage[kPepCC] as? NSArray {
            add(pEpIdentities: recipients as! [PEPIdentity], toPantomimeMessage: message,
                recipientType: .ccRecipient)
        }
        if let recipients = pEpMessage[kPepBCC] as? NSArray {
            add(pEpIdentities: recipients as! [PEPIdentity], toPantomimeMessage: message,
                recipientType: .bccRecipient)
        }
        if let messageID = pEpMessage[kPepID] as? String {
            message.setMessageID(messageID)
        }
        if let sentDate = pEpMessage[kPepSent] as? Date {
            message.setOriginationDate(sentDate)
        }
        if let shortMsg = pEpMessage[kPepShortMessage] as? String {
            message.setSubject(shortMsg)
        }

        // Go over all references and inReplyTo, and add all the uniques
        // as references, with the inReplyTo last
        // (https://cr.yp.to/immhf/thread.html)
        let allRefsAdded = NSMutableOrderedSet()
        if let refs = pEpMessage[kPepReferences] as? [AnyObject] {
            for ref in refs {
                allRefsAdded.add(ref)
            }
        }
        if let inReplyTos = pEpMessage[kPepInReplyTo] as? [AnyObject] {
            for inReplyTo in inReplyTos {
                allRefsAdded.add(inReplyTo)
            }
        }
        message.setReferences(allRefsAdded.array)

        // deal with MIME type

        let attachmentDictsOpt = pEpMessage[kPepAttachments] as? NSArray
        if !MiscUtil.isNilOrEmptyNSArray(attachmentDictsOpt) {
            let encrypted = isProbablyPGPMime(pEpMessage: pEpMessage)

            // Create multipart mail
            let multiPart = CWMIMEMultipart()
            if encrypted {
                message.setContentType(Constants.contentTypeMultipartEncrypted)
                message.setParameter(Constants.protocolPGPEncrypted, forKey: "protocol")
            } else {
                message.setContentType(Constants.contentTypeMultipartMixed)
            }
            message.setContent(multiPart)

            if !encrypted {
                if let bodyPart = bodyPart(pEpMessage: pEpMessage) {
                    multiPart.add(bodyPart)
                }
            }

            if let attachmentDicts = attachmentDictsOpt {
                for attachmentDict in attachmentDicts {
                    guard let at = attachmentDict as? [String:NSObject]  else {
                        continue
                    }
                    let part = CWPart()
                    part.setContentType(at[kPepMimeType] as? String)
                    part.setContent(at[kPepMimeData])
                    part.setFilename(at[kPepMimeFilename] as? String)
                    multiPart.add(part)
                }
            }
        } else {
            if let body = bodyPart(pEpMessage: pEpMessage) {
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
    static func bodyPart(pEpMessage: PEPMessage) -> CWPart? {
        let theBodyParts = bodyParts(pEpMessage: pEpMessage)
        if theBodyParts.count == 1 {
            return theBodyParts[0]
        } else if theBodyParts.count > 1 {
            let partAlt = CWPart()
            partAlt.setContentType(Constants.contentTypeMultipartAlternative)
            let partMulti = CWMIMEMultipart()
            for part in theBodyParts {
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
    static func makePart(text: String?, contentType: String) -> CWPart? {
        if let t = text {
            let part = CWPart()
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
    static func bodyParts(pEpMessage: PEPMessage) -> [CWPart] {
        var parts: [CWPart] = []

        if let part = makePart(text: pEpMessage[kPepLongMessage] as? String,
                               contentType: Constants.contentTypeText) {
            parts.append(part)
        }
        if let part = makePart(text: pEpMessage[kPepLongMessageFormatted] as? String,
                               contentType: Constants.contentTypeHtml) {
            parts.append(part)
        }

        return parts
    }

    open static func pEpRating(cdIdentity: CdIdentity,
                               session: PEPSession = PEPSession()) -> PEP_rating {
        let pepC = pEp(cdIdentity: cdIdentity)
        let rating = session.identityRating(pepC)
        return rating
    }

    open static func pEpColor(cdIdentity: CdIdentity,
                              session: PEPSession = PEPSession()) -> PEP_color {
        return pEpColor(pEpRating: pEpRating(cdIdentity: cdIdentity, session: session))
    }

    open static func pEpRating(identity: Identity,
                               session: PEPSession = PEPSession()) -> PEP_rating {
        let pepC = pEp(identity: identity)
        let rating = session.identityRating(pepC)
        return rating
    }

    open static func pEpColor(identity: Identity,
                              session: PEPSession = PEPSession()) -> PEP_color {
        return pEpColor(pEpRating: pEpRating(identity: identity, session: session))
    }

    open static func pEpColor(pEpRating: PEP_rating) -> PEP_color {
        return color_from_rating(pEpRating)
    }

    open static func pEpRatingFromInt(_ i: Int?) -> PEP_rating? {
        guard let theInt = i else {
            return nil
        }
        if theInt == Int(pEpRatingNone) {
            return PEP_rating_undefined
        }
        return PEP_rating(Int32(theInt))
    }

    open static func pEpTitle(pEpRating: PEP_rating) -> String? {
        if let (title, _, _) = PEPUtil.pEpRatingTranslations[pEpRating] {
            return title
        }
        Log.warn(component: comp, content: "No privacy title for color rating \(pEpRating)")
        return nil
    }

    open static func pEpExplanation(pEpRating: PEP_rating) -> String? {
        if let (_, explanation, _) = PEPUtil.pEpRatingTranslations[pEpRating] {
            return explanation
        }
        Log.warn(component: comp, content: "No privacy explanation for color rating \(pEpRating)")
        return nil
    }

    open static func pEpSuggestion(pEpRating: PEP_rating) -> String? {
        if let (_, _, suggestion) = pEpRatingTranslations[pEpRating] {
            return suggestion
        }
        Log.warn(component: comp, content: "No privacy suggestion for color rating \(pEpRating)")
        return nil
    }

    open static func trustwords(identity1: PEPIdentity, identity2: PEPIdentity,
                                language: String, full: Bool = true,
                                session: PEPSession = PEPSession()) -> String? {
        return session.getTrustwordsIdentity1(identity1, identity2: identity2,
                                              language: language, full: full)
    }

    open static func fingerPrint(identity: Identity, session: PEPSession = PEPSession()) -> String? {
        let pEpID = pEp(identity: identity)
        let pEpDict = NSMutableDictionary(dictionary: pEpID)
        session.updateIdentity(pEpDict)
        return pEpDict[kPepFingerprint] as? String
    }

    /**
     Trust that contact (yellow to green).
     */
    open static func trust(identity: Identity, session: PEPSession = PEPSession()) {
        let pepC = NSMutableDictionary(dictionary: pEp(identity: identity))
        session.updateIdentity(pepC)
        session.trustPersonalKey(pepC)
    }

    /**
     Mistrust the identity (yellow to red)
     */
    open static func mistrust(identity: Identity, session: PEPSession = PEPSession()) {
        let pepC = NSMutableDictionary(dictionary: pEp(identity: identity))
        session.updateIdentity(pepC)
        session.keyMistrusted(pepC)
    }

    /**
     Resets the trust for the given `Identity`. Use both for trusting again after
     mistrusting a key, and for mistrusting a key after you have first trusted it.
     */
    open static func resetTrust(identity: Identity, session: PEPSession = PEPSession()) {
        let pepC = NSMutableDictionary(dictionary: pEp(identity: identity))
        session.updateIdentity(pepC)
        session.keyResetTrust(pepC)
    }

    open static func encrypt(
        pEpMessageDict: PEPMessage, forIdentity: PEPIdentity? = nil,
        session: PEPSession = PEPSession()) -> (PEP_STATUS, NSDictionary?) {
        var encryptedMessage: NSDictionary? = nil

        if let ident = forIdentity {
            let pepStatus = session.encryptMessageDict(
                pEpMessageDict, identity: ident,
                dest: &encryptedMessage)
            return (pepStatus, encryptedMessage)
        } else {
            let pepStatus = session.encryptMessageDict(
                pEpMessageDict, extra: nil,
                dest: &encryptedMessage)
            return (pepStatus, encryptedMessage)
        }
    }

    /**
     Checks the given pEp status and the given encrypted mail for errors and
     logs them.
     - Returns: A tuple of the encrypted mail and an error. Both can be nil.
     */
    static func check(comp: String, status: PEP_STATUS,
                      encryptedMessage: NSDictionary?) -> (NSDictionary?, NSError?) {
        if encryptedMessage != nil && status == PEP_UNENCRYPTED {
            // Don't interpret that as an error
            return (encryptedMessage, nil)
        }
        if encryptedMessage == nil || status != PEP_STATUS_OK {
            let error = Constants.errorEncryption(comp, status: status)
            Log.error(component: comp, error: Constants.errorInvalidParameter(
                comp, errorMessage: "Could not encrypt message, pEp status \(status)"))
            return (encryptedMessage, error)
        }
        return (encryptedMessage, nil)
    }

    public static func trustwordsLanguages() -> [TrustwordsLanguage] {
        // TODO: Hook up with real data from the engine
        return [
            TrustwordsLanguage(languageCode: "en", languageName: "English"),
            TrustwordsLanguage(languageCode: "de", languageName: "German"),
        ]
    }
    
    public static func mySelfIdentity(_ message: Message) -> Identity? {
        let allRecipients = Array(message.allIdentities)
        let mySelfIdent = message.parent!.account!.user
        for recipient in allRecipients {
            if mySelfIdent.isMySelf == true && recipient.address == mySelfIdent.address {
                return recipient
            }
        }
        return nil
    }
    
    public static func systemLanguage() -> String {
        let language = Bundle.main.preferredLocalizations.first
        print("LANG: \(language)")
        return language!
    }
}

extension String {
    
    public static var pepSignature: String {
        return "pEp.Mail.Signature".localized
    }
}

extension UIColor {
    
    open class var pEpGreen: UIColor {
        get {
            return .green //(hex: "#03AA4B")
        }
    }
    
    open class var pEpNoColor: UIColor {
        get {
            return .gray //(hex: "#B4B0B0")
        }
    }
    
    open class var pEpRed: UIColor {
        get {
            return .red //(hex: "#D0011B")
        }
    }
    
    open class var pEpYellow: UIColor {
        get {
            return .yellow //UIColor(hex: "#FFC901")
        }
    }
    
    open class var pEpBlue: UIColor {
        get {
            return .blue //UIColor(hex: "#007AFF")
        }
    }
    
    convenience init(hex: String) {
        var hexstr = hex
        if hexstr.hasPrefix("#") {
            hexstr = String(hexstr.characters.dropFirst())
        }
        
        var rgbValue: UInt32 = 0
        Scanner(string: hexstr).scanHexInt32(&rgbValue)
        
        let r = CGFloat((rgbValue >> 16) & 0xff) / 255.0
        let g = CGFloat((rgbValue >> 08) & 0xff) / 255.0
        let b = CGFloat((rgbValue >> 00) & 0xff) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

extension UIFont {
    
    open class var pEpInput: UIFont {
        get {
            return self.systemFont(ofSize: 14.0)
        }
    }
}

extension NSDictionary {
    func pEpIdentity() -> PEPIdentity {
        var id = PEPIdentity()
        for (k, v) in self {
            if let ks = k as? String {
                id[ks] = v as AnyObject
            }
        }
        return id
    }
}
