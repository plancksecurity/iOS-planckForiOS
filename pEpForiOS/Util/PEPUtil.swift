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

public class PEPUtil {
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
     Converts a core data contact to a pEp contact.
     - Parameter contact: The core data contact object.
     - Returns: An `NSMutableDictionary` contact for pEp.
     */
    public static func pepContact(contact: IContact) -> NSMutableDictionary {
        let dict: NSMutableDictionary = [:]
        if let name = contact.name {
            dict[kPepUsername] = name
        }
        dict[kPepAddress] = contact.email
        if let userID = contact.userID {
            dict[kPepUserID] = userID
        }
        return dict
    }

    /**
     Creates pEp contact from name and address.
     */
    public static func pepContactFromEmail(email: String, name: String? = nil) -> PEPContact {
        let contact = NSMutableDictionary()
        contact[kPepAddress] = email
        if let n = name {
            contact[kPepUsername] = n
        }
        return contact
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

    public static func insertPepContact(
        pepContact: PEPContact, intoModel: IModel) -> IContact {
        let contact = intoModel.insertOrUpdateContactEmail(
            pepContact[kPepAddress] as! String,
            name: pepContact[kPepUsername] as? String)
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
        let color = session.identityColor(pepC)
        return color
    }

    public static func abstractPepColorFromPepColor(pepColorRating: PEP_color) -> PrivacyColor {
        return .NoColor
    }

    public static func pepColorRatingFromInt(i: Int) -> PEP_color {
        return PEP_rating_undefined
    }
}