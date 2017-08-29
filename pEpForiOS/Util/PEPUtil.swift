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
     Default pEpRating value when there's none, i.e. the message has never been decrypted.
     */
    public static let pEpRatingNone = CdMessage.pEpRatingNone

    /**
     Content type for MIME multipart/alternative.
     */
    open static let kMimeTypeMultipartAlternative = "multipart/alternative"

    /** Delete pEp working data. */
    open static func pEpClean() -> Bool {
        let homeURL = PEPObjCAdapter.homeURL() as URL
        let keyRingURL = homeURL.appendingPathComponent(".gnupg")

        let pEpItemsToDelete: [URL] = [
            homeURL.appendingPathComponent(".pEp_management.db"),
            keyRingURL.appendingPathComponent("secring.gpg"),
            keyRingURL.appendingPathComponent("pubring.gpg"),
            ]

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
        return dict
    }

    /**
     Creates pEp contact just from name and address.
     */
    open static func pEpIdentity(email: String, name: String) -> PEPIdentity {
        var identity = PEPIdentity()
        identity[kPepAddress] = email as AnyObject
        identity[kPepUsername] = name as AnyObject
        return identity
    }

    open static func pEpOptional(identity: Identity?) -> PEPIdentity? {
        guard let id = identity else {
            return nil
        }
        return pEp(identity: id)
    }

    open static func pEpAttachment(
        fileName: String?, mimeType: String?, data: Data?) -> [String: AnyObject] {
        var dict: [String: AnyObject] = [:]
        if let fn = fileName {
            dict[kPepMimeFilename] = fn as NSString
        }
        if let mt = mimeType {
            dict[kPepMimeType] = mt as NSString
        }
        if let d = data {
            dict[kPepMimeData] = d as NSData
        }
        return dict
    }

    /**
     Converts a `CdAttachment` into a pEp attachment.
     */
    open static func pEp(cdAttachment: CdAttachment) -> [String: AnyObject] {
        return pEpAttachment(
            fileName: cdAttachment.fileName, mimeType: cdAttachment.mimeType,
            data: cdAttachment.data as Data?)
    }

    /**
     Converts an `Attachment` into a pEp attachment.
     */
    open static func pEp(attachment: Attachment) -> [String: AnyObject] {
        return pEpAttachment(
            fileName: attachment.fileName, mimeType: attachment.mimeType, data: attachment.data)
    }

    open static func pEp(message: Message, outgoing: Bool = true) -> PEPMessage {
        var dict = PEPMessage()

        if let subject = message.shortMessage {
            dict[kPepShortMessage] = subject as NSString
        }

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
            dict[kPepShortMessage] = subject as NSString
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

        dict[kPepAttachments] = NSArray(
            array: (cdMessage.attachments?.array as? [CdAttachment] ?? []).map() {
                return pEp(cdAttachment: $0)
        })

        var refs = [String]()
        for ref in cdMessage.references?.array as? [CdMessageReference] ?? [] {
            if let refString = ref.reference {
                refs.append(refString)
            }
        }

        if refs.count > 0 {
            dict[kPepReferences] = refs as AnyObject
        }

        if let r = cdMessage.replyTo {
            dict[kPepReplyTo] = r.array as AnyObject
        }

        dict[kPepReplyTo] = NSArray(array: cdMessage.replyTo!.map()
            { return pEp(cdIdentity: $0 as! CdIdentity) })

        let headerFields = cdMessage.optionalFields?.array as? [CdHeaderField] ?? []
        var theFields = [(String, String)]()
        for field in headerFields {
            if let name = field.name, let value = field.value {
                theFields.append((name, value))
            }
        }
        if !theFields.isEmpty {
            dict[kPepOptFields] = NSArray(
                array: theFields.map() {
                    return NSArray(array: [$0.0, $0.1])
            })
        }

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

    open static func pantomime(pEpMessage: PEPMessage,
                               mailboxName: String? = nil) -> CWIMAPMessage {
        return CWIMAPMessage(pEpMessage: pEpMessage, mailboxName: mailboxName)
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
            part.setContentTransferEncoding(PantomimeEncoding8bit)
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
                               session: PEPSession) -> PEP_rating {
        let pepC = pEp(cdIdentity: cdIdentity)
        let rating = session.identityRating(pepC)
        return rating
    }

    open static func pEpColor(cdIdentity: CdIdentity,
                              session: PEPSession) -> PEP_color {
        return pEpColor(pEpRating: pEpRating(cdIdentity: cdIdentity, session: session))
    }

    open static func pEpRating(identity: Identity,
                               session: PEPSession) -> PEP_rating {
        let pepC = pEp(identity: identity)
        let rating = session.identityRating(pepC)
        return rating
    }

    open static func outgoingMessageColor(from: Identity, to: [Identity],
                                          cc: [Identity], bcc: [Identity],
                                          session: PEPSession) -> PEP_rating {
        let fakeFolder: Folder
        if let account = Account.by(address: from.address) {
            fakeFolder = Folder(parent: nil, uuid: "fakeuuid", name: "fakename", account:account)
        } else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "No account exists for Identity \"from\". That is inconsitant DB state and thus not allowed")
            let fakeId = Identity(address: "fake@address.com", userID: nil, userName: "fakeName",
                                  isMySelf: true)
            let fakeAccount = Account(user: fakeId, servers: [Server]())
            fakeFolder = Folder(parent: nil, uuid: "fakeuuid", name: "fakename", account:fakeAccount)
        }

        let fakemail = Message(uuid: "fakeuuid", parentFolder: fakeFolder)
        fakemail.from = from
        fakemail.to = to
        fakemail.cc = cc
        fakemail.bcc = bcc
        fakemail.shortMessage = ""
        fakemail.longMessage = ""
        return session.outgoingMessageColor(fakemail.pEpMessage(message: fakemail, outgoing: true))
    }

    open static func pEpColor(identity: Identity,
                              session: PEPSession) -> PEP_color {
        return pEpColor(pEpRating: pEpRating(identity: identity, session: session))
    }

    open static func pEpColor(pEpRating: PEP_rating?) -> PEP_color {
        if let rating = pEpRating {
            return color_from_rating(rating)
        } else {
            return PEP_color_no_color
        }
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

    open static func trustwords(identity1: PEPIdentity, identity2: PEPIdentity,
                                language: String, full: Bool = true,
                                session: PEPSession) -> String? {
        return session.getTrustwordsIdentity1(identity1, identity2: identity2,
                                              language: language, full: full)
    }

    open static func fingerPrint(identity: Identity, session: PEPSession) -> String? {
        let pEpID = pEp(identity: identity)
        let pEpDict = NSMutableDictionary(dictionary: pEpID)
        session.updateIdentity(pEpDict)
        return pEpDict[kPepFingerprint] as? String
    }

    open static func fingerPrint(cdIdentity: CdIdentity,
                                 session: PEPSession) -> String? {
        let pEpID = pEp(cdIdentity: cdIdentity)
        let pEpDict = NSMutableDictionary(dictionary: pEpID)
        session.updateIdentity(pEpDict)
        return pEpDict[kPepFingerprint] as? String
    }

    /**
     Trust that contact (yellow to green).
     */
    open static func trust(identity: Identity, session: PEPSession) {
        let pepC = NSMutableDictionary(dictionary: pEp(identity: identity))
        session.updateIdentity(pepC)
        session.trustPersonalKey(pepC)
    }

    /**
     Mistrust the identity (yellow to red)
     */
    open static func mistrust(identity: Identity, session: PEPSession) {
        let pepC = NSMutableDictionary(dictionary: pEp(identity: identity))
        session.updateIdentity(pepC)
        session.keyMistrusted(pepC)
    }

    /**
     Resets the trust for the given `Identity`. Use both for trusting again after
     mistrusting a key, and for mistrusting a key after you have first trusted it.
     */
    open static func resetTrust(identity: Identity, session: PEPSession) {
        let pepC = NSMutableDictionary(dictionary: pEp(identity: identity))
        session.updateIdentity(pepC)
        session.keyResetTrust(pepC)
    }

    open static func encrypt(
        pEpMessageDict: PEPMessage, forIdentity: PEPIdentity? = nil,
        session: PEPSession) -> (PEP_STATUS, NSDictionary?) {
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

    public static func ownIdentity(message: Message) -> Identity? {
        return message.parent.account.user
    }

    public static func systemLanguage() -> String {
        let language = Bundle.main.preferredLocalizations.first
        return language!
    }
}

extension String {
    public static var pepSignature: String {
        let bottom = NSLocalizedString(
            "Sent with p≡p", comment: "pEp mail signature. Newlines will be added by app")
        return "\n\n\(bottom)\n"
    }
}

extension UIFont {
    open class var pEpInput: UIFont {
        get {
            return UIFont.preferredFont(forTextStyle: .body)
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
