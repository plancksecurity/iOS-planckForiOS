//
//  PEPUtil.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

public enum PrivacyColor {
    case NoColor
    case Green
    case Red
    case Yellow
}

var pepColorDictionary: [Int32: PEP_color] =
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

var pepExplanationDictionary: [Int32: String] =
    [PEP_rating_under_attack.rawValue: "Under Attack",
    PEP_rating_b0rken.rawValue: "-",
    PEP_rating_mistrust.rawValue: "Mistrusted",

    PEP_rating_fully_anonymous.rawValue: "Secure & Trusted",

    PEP_rating_trusted_and_anonymized.rawValue: "Secure & Trusted",
    PEP_rating_trusted.rawValue: "Secure & Trusted",
    PEP_rating_reliable.rawValue: "Secure",
    PEP_rating_unreliable.rawValue: "Unreliable Security",
    PEP_rating_unencrypted_for_some.rawValue: "Unsecure for Some",
    PEP_rating_unencrypted.rawValue: "Unsecure",
    PEP_rating_have_no_key.rawValue: "Cannot Decrypt",
    PEP_rating_cannot_decrypt.rawValue: "Cannot Decrypt",
    PEP_rating_undefined.rawValue: "Unknown"]


public class PEPUtil {
    static let comp = "PEPUtil"

    /**
     Content type for MIME multipart/alternative.
     */
    public static let kMimeTypeMultipartAlternative = "multipart/alternative"

    private static let homeUrl = NSURL(fileURLWithPath:
                                      NSProcessInfo.processInfo().environment["HOME"]!)
    private static let pEpManagementDbUrl =
                                         homeUrl.URLByAppendingPathComponent(".pEp_management.db")
    private static let systemDbUrl = homeUrl.URLByAppendingPathComponent("system.db")
    private static let gnupgUrl = homeUrl.URLByAppendingPathComponent(".gnupg")
    private static let gnupgSecringUrl = gnupgUrl.URLByAppendingPathComponent("secring.gpg")
    private static let gnupgPubringUrl = gnupgUrl.URLByAppendingPathComponent("pubring.gpg")
    
    // Provide filepath URLs as public dictionary.
    public static let pEpUrls: [String:NSURL] = [
                      "home": homeUrl,
                      "pEpManagementDb": pEpManagementDbUrl,
                      "systemDb": systemDbUrl,
                      "gnupg": gnupgUrl,
                      "gnupgSecring": gnupgSecringUrl,
                      "gnupgPubring": gnupgPubringUrl]
    
    // Delete pEp working data.
    public static func pEpClean() -> Bool {
        let pEpItemsToDelete: [String] = ["pEpManagementDb", "gnupg", "systemDb"]
        var error: NSError?
        
        for key in pEpItemsToDelete {
            let fileManager: NSFileManager = NSFileManager.defaultManager()
            let itemToDelete: NSURL = pEpUrls[key]!
            if itemToDelete.checkResourceIsReachableAndReturnError(&error) {
                do {
                    try fileManager.removeItemAtURL(itemToDelete)
                }
                catch {
                    return false
                }
            }
        }
        return true
    }

    public static func identityFromAccount(account: IAccount,
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
    public static func myselfFromAccount(account: Account,
                                         block: ((identity: NSDictionary) -> Void)? = nil) {
        let op = PEPMyselfOperation.init(account: account)
        op.completionBlock = {
            if let bl = block {
                bl(identity: op.identity)
            }
        }
        let queue = NSOperationQueue.init()
        queue.addOperation(op)
    }

    /**
     Converts an IContact (possibly from core data) to a pEp contact.
     - Parameter contact: The core data contact object.
     - Returns: An `NSMutableDictionary` contact for pEp.
     */
    public static func pepContact(contact: IContact) -> PEPContact {
        let dict: NSMutableDictionary = [:]
        if let name = contact.name {
            dict[kPepUsername] = name
        } else {
            dict[kPepUsername] = contact.email.namePartOfEmail()
        }
        dict[kPepAddress] = contact.email
        if contact.isMySelf.boolValue {
            dict[kPepIsMe] = true
        }

        if let pepUserID = contact.pepUserID {
            dict[kPepUserID] = pepUserID
        } else {
            // Only use an address book ID if this contact has no pEp ID
            if let addressBookID = contact.addressBookID {
                dict[kPepUserID] = String(addressBookID)
            }
        }
        return dict as PEPContact
    }

    /**
     Creates pEp contact from name and address. Useful for tests where you don't want
     more data filled in.
     */
    public static func pepContactFromEmail(email: String, name: String) -> PEPContact {
        let contact = NSMutableDictionary()
        contact[kPepAddress] = email
        contact[kPepUsername] = name
        return contact as PEPContact
    }

    /**
     Converts a core data attachment to a pEp attachment.
     - Parameter contact: The core data attachment object.
     - Returns: An `NSMutableDictionary` attachment for pEp.
     */
    public static func pepAttachment(attachment: IAttachment) -> NSMutableDictionary {
        let dict: NSMutableDictionary = [:]

        if let filename = attachment.filename {
            dict[kPepMimeFilename] = filename
        }
        if let contentType = attachment.contentType {
            dict[kPepMimeType] = contentType
        }
        dict[kPepMimeData] = attachment.content.data

        return dict
    }

    /**
     Converts a core data message into the format required by pEp.
     - Parameter message: The core data message to convert
     - Returns: An object (`NSMutableDictionary`) suitable for processing with pEp.
     */
    public static func pepMail(message: IMessage, outgoing: Bool = true) -> PEPMail {
        let dict: NSMutableDictionary = [:]

        if let subject = message.subject {
            dict[kPepShortMessage] = subject
        }

        dict[kPepTo] = message.to.map() { pepContact($0 as! Contact) }
        dict[kPepCC] = message.cc.map() { pepContact($0 as! Contact) }
        dict[kPepBCC] = message.bcc.map() { pepContact($0 as! Contact) }

        if let longMessage = message.longMessage {
            dict[kPepLongMessage] = longMessage
        }
        if let longMessageFormatted = message.longMessageFormatted {
            dict[kPepLongMessageFormatted] = longMessageFormatted
        }
        if let from = message.from {
            dict[kPepFrom]  = self.pepContact(from)
        }
        if let messageID = message.messageID {
            dict[kPepID] = messageID
        }
        dict[kPepOutgoing] = outgoing

        dict[kPepAttachments] = message.attachments.map() { pepAttachment($0 as! IAttachment) }

        return dict as PEPMail
    }

    public static func insertPepContact(pepContact: PEPContact, intoModel: IModel) -> IContact {
        let contact = intoModel.insertOrUpdateContactEmail(
            pepContact[kPepAddress] as! String,
            name: pepContact[kPepUsername] as? String)
        if let isMySelf = pepContact[kPepIsMe] as? Bool {
            contact.isMySelf = isMySelf
        }

        // The only case where the kPepUserID is already set, should
        // be as a result of mySelf().
        if let pepUserID = pepContact[kPepUserID] as? String {
            contact.pepUserID = pepUserID
        }
        // If there is no pEp ID yet, try to use an addressbook ID
        if contact.pepUserID == nil {
            if let abID = contact.addressBookID?.intValue {
                contact.pepUserID = String(abID)
            }
        }
        return contact
    }

    /**
     For a PEPMail, checks whether it is PGP/MIME encrypted.
     */
    public static func isProbablyPGPMime(message: PEPMail) -> Bool {
        var foundAttachmentPGPEncrypted = false
        let attachments = message[kPepAttachments] as! NSArray
        for atch in attachments {
            if let filename = atch[kPepMimeType] as? String {
                if filename.lowercaseString == Constants.contentTypePGPEncrypted {
                    foundAttachmentPGPEncrypted = true
                    break
                }
            }
        }
        return foundAttachmentPGPEncrypted
    }

    /**
     Converts a pEp contact dict to a pantomime address.
     */
    public static func pantomimeContactFromPepContact(contact: PEPContact) -> CWInternetAddress {
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
    public static func makePantomimeRecipientsFromPepContacts(pepContacts: [PEPContact],
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

    public static func addPepContacts(recipients: [PEPContact], toPantomimeMessage: CWIMAPMessage,
                                      recipientType: PantomimeRecipientType) {
        let addresses = makePantomimeRecipientsFromPepContacts(
            recipients, recipientType: recipientType)
        for a in addresses {
            toPantomimeMessage.addRecipient(a)
        }
    }

    /**
     Converts a given `PEPMail` into the equivalent `CWIMAPMessage`.
     See https://tools.ietf.org/html/rfc2822 for a better understanding of some fields.
     */
    public static func pantomimeMailFromPep(pepMail: PEPMail) -> CWIMAPMessage {
        if let rawMessageData = pepMail[kPepRawMessage] as? NSData {
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
                          recipientType: .ToRecipient)
        }
        if let recipients = pepMail[kPepCC] as? NSArray {
            addPepContacts(recipients as! [PEPContact], toPantomimeMessage: message,
                          recipientType: .CcRecipient)
        }
        if let recipients = pepMail[kPepBCC] as? NSArray {
            addPepContacts(recipients as! [PEPContact], toPantomimeMessage: message,
                          recipientType: .BccRecipient)
        }
        if let messageID = pepMail[kPepID] as? String {
            message.setMessageID(messageID)
        }
        if let shortMsg = pepMail[kPepShortMessage] as? String {
            message.setSubject(shortMsg)
        }
        if let refs = pepMail[kPepReferences] as? [AnyObject] {
            message.setReferences(refs)
        }
        if let inReplyTo = pepMail[kPepReferences] as? NSArray {
            let s = inReplyTo.componentsJoinedByString(" ")
            message.setInReplyTo(s)
        }

        // deal with MIME type

        let attachmentDictsOpt = pepMail[kPepAttachments] as? NSArray
        if !MiscUtil.isNilOrEmptyNSArray(attachmentDictsOpt) {
            // Create multipart mail
            let multiPart = CWMIMEMultipart.init()
            message.setContentType(Constants.contentTypeMultipartMixed)
            message.setContent(multiPart)

            let bodyPart = bodyPartFromPepMail(pepMail)
            multiPart.addPart(bodyPart)

            if let attachmentDicts = attachmentDictsOpt {
                for attachmentDict in attachmentDicts {
                    let part = CWPart.init()
                    part.setContentType(attachmentDict[kPepMimeType] as? String)
                    part.setContent(attachmentDict[kPepMimeData] as? NSData)
                    part.setFilename(attachmentDict[kPepMimeFilename] as? String)
                    multiPart.addPart(part)
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
    static func bodyPartFromPepMail(pepMail: PEPMail) -> CWPart? {
        let bodyParts = bodyPartsFromPepMail(pepMail)
        if bodyParts.count == 1 {
            return bodyParts[0]
        } else if bodyParts.count > 1 {
            let partAlt = CWPart.init()
            partAlt.setContentType(Constants.contentTypeMultipartAlternative)
            let partMulti = CWMIMEMultipart.init()
            for part in bodyParts {
                partMulti.addPart(part)
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
    static func makePartFromText(text: String?, contentType: String) -> CWPart? {
        if let t = text {
            let part = CWPart.init()
            part.setContentType(contentType)
            part.setContent(t.dataUsingEncoding(NSUTF8StringEncoding))
            part.setCharset("UTF-8")
            return part
        }
        return nil
    }

    /**
     Extracts text content from a pEp mail as a list of pantomime part object.
     - Returns: A list of pantomime parts. This list can have 0, 1 or 2 elements.
     */
    static func bodyPartsFromPepMail(pepMail: PEPMail) -> [CWPart] {
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

    public static func colorRatingForContact(contact: IContact) -> PEP_color {
        let pepC = pepContact(contact)
        let session = PEPSession.init()
        let color = session.identityColor(pepC as [NSObject : AnyObject])
        return color
    }

    public static func colorFromPepColorRating(pepColorRating: PEP_color) -> PrivacyColor {
        switch pepColorRating {
        case PEP_rating_undefined,
             PEP_rating_cannot_decrypt,
             PEP_rating_have_no_key,
             PEP_rating_unencrypted,
             PEP_rating_unencrypted_for_some,
             PEP_rating_unreliable:
            return .NoColor
        case PEP_rating_reliable,
             PEP_rating_yellow:
            return .Yellow
        case PEP_rating_trusted,
             PEP_rating_green,
             PEP_rating_trusted_and_anonymized,
             PEP_rating_fully_anonymous:
            return .Green
        case PEP_rating_mistrust,
             PEP_rating_red,
             PEP_rating_b0rken,
             PEP_rating_under_attack:
            return .Red

        // TODO: Is this a Swift bug? The code would be safer without a default, in case
        // PEP_color gains elements.
        default:
            Log.warnComponent(self.comp, "Unsupported color rating")
            return .NoColor
        }
    }

    public static func pepColorRatingFromInt(i: Int) -> PEP_color? {
        let int32 = Int32(i)
        return pepColorDictionary[int32]
    }

    public static func pepExplanationFromColor(pepColorRating: PEP_color) -> String? {
        return pepExplanationDictionary[pepColorRating.rawValue]
    }

    public static func sessionOrReuse(session: PEPSession?) -> PEPSession {
        if session == nil {
            return PEPSession.init()
        }
        return session!
    }

    /**
     - Returns: The short trustwords for a fingerprint as one single String.
     */
    public static func shortTrustwordsForFpr(fpr: String, language: String,
                                             session: PEPSession?) -> String {
        let words = sessionOrReuse(session).trustwords(
            fpr, forLanguage: language, shortened: true) as! [String]
        return words.joinWithSeparator(" ")
    }

    public static func trustwordsForIdentity1(identity1: PEPContact,
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
        case .OrderedAscending, .OrderedSame:
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
    public static func updateDecryptedMessage(message: IMessage, fromPepMail: PEPMail,
                                              pepColorRating: PEP_color?, model: IModel) {
        if let color = pepColorRating {
            message.pepColorRating = NSNumber.init(int: color.rawValue)
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
                if let data = atDict[kPepMimeData] as? NSData {
                    let attach = model.insertAttachmentWithContentType(
                        atDict[kPepMimeType] as? String,
                        filename: atDict[kPepMimeFilename] as? String,
                        data: data)
                    attachments.append(attach)
                }
            }
        }
        message.attachments = NSOrderedSet.init(array: attachments)
    }

    /**
     - Returns: An NSOrderedSet that contains all elements of `array`. If `array` is nil,
     the ordered set is empty.
     */
    public static func orderedContactSetFromPepContactArray(
        array: NSArray?, model: IModel) -> NSOrderedSet {
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
    public static func updateWholeMessage(message: IMessage, fromPepMail: PEPMail, model: IModel) {
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
}