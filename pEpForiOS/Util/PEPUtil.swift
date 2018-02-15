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
        PEPSession.cleanup()

        let homeURL = PEPObjCAdapter.homeURL() as URL
        let keyRingURL = homeURL.appendingPathComponent(".gnupg")

        let pEpItemsToDelete: [URL] = [
            homeURL.appendingPathComponent(".pEp_management.db"),
            homeURL.appendingPathComponent(".pEp_management.db-shm"),
            homeURL.appendingPathComponent(".pEp_management.db-wal"),
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
            return pEpDict(cdIdentity: id)
        } else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "account without identity: \(account)")
            return PEPIdentity(address: "none")
        }
    }

    open static func pEp(identity: Identity) -> PEPIdentity {
        return PEPIdentity(
            address: identity.address, userID: identity.userID, userName: identity.userName,
            isOwn: identity.isMySelf, fingerPrint: nil, commType: PEP_ct_unknown, language: nil)
    }

    /**
     Like the corresponding `pEpDict(cdIdentity)`, but dealing with optional parameters.
     */
    open static func pEpDict(cdIdentityOptional: CdIdentity?) -> PEPIdentity? {
        guard let cdIdentity = cdIdentityOptional else {
            return nil
        }
        return pEpDict(cdIdentity: cdIdentity)
    }

    /**
     Converts a `CdIdentity` to a pEp contact (`PEPId`).
     - Parameter cdIdentity: The core data contact object.
     - Returns: An `PEPIdentity` contact for pEp.
     */
    open static func pEpDict(cdIdentity: CdIdentity) -> PEPIdentity {
        if let address = cdIdentity.address {
            return PEPIdentity(address: address, userID: cdIdentity.userID,
                               userName: cdIdentity.userName, isOwn: cdIdentity.isMySelf,
                               fingerPrint: nil, commType: PEP_ct_unknown, language: nil)
        } else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "missing address: \(cdIdentity)")
            return PEPIdentity(address: "none")
        }
    }

    /**
     Creates pEp contact just from name and address.
     */
    open static func pEpIdentity(email: String, name: String) -> PEPIdentityDict {
        var identity = PEPIdentityDict()
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
    open static func pEpDict(cdAttachment: CdAttachment) -> [String: AnyObject] {
        return pEpAttachment(
            fileName: cdAttachment.fileName, mimeType: cdAttachment.mimeType,
            data: cdAttachment.data as Data?)
    }

    /**
     Converts an `Attachment` into a pEp attachment.
     */
    open static func pEpDict(attachment: Attachment) -> [String: AnyObject] {
        return pEpAttachment(
            fileName: attachment.fileName, mimeType: attachment.mimeType, data: attachment.data)
    }

    open static func pEpDict(message: Message, outgoing: Bool = true) -> PEPMessageDict {
        var dict = PEPMessageDict()

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
            return pEpDict(attachment: $0)
        })

        dict[kPepReferences] = message.references as AnyObject

        return dict
    }

    /**
     Converts a core data message into the format required by pEp.
     - Parameter message: The core data message to convert
     - Returns: An object (`NSMutableDictionary`) suitable for processing with pEp.
     */
    open static func pEpDict(cdMessage: CdMessage, outgoing: Bool = true) -> PEPMessageDict {
        var dict = PEPMessageDict()

        if let sent = cdMessage.sent {
            dict[kPepSent] = sent as NSDate
        }

        if let subject = cdMessage.shortMessage {
            dict[kPepShortMessage] = subject as NSString
        }

        dict[kPepTo] = NSArray(array: cdMessage.to!.map()
            { return pEpDict(cdIdentity: $0 as! CdIdentity) })
        dict[kPepCC] = NSArray(array: cdMessage.cc!.map()
            { return pEpDict(cdIdentity: $0 as! CdIdentity) })
        dict[kPepBCC] = NSArray(array: cdMessage.bcc!.map()
            { return pEpDict(cdIdentity: $0 as! CdIdentity) })

        if let longMessage = cdMessage.longMessage {
            dict[kPepLongMessage] = longMessage as AnyObject
        }
        if let longMessageFormatted = cdMessage.longMessageFormatted {
            dict[kPepLongMessageFormatted] = longMessageFormatted as AnyObject
        }
        if let from = cdMessage.from {
            dict[kPepFrom]  = self.pEpDict(cdIdentity: from) as AnyObject
        }
        if let messageID = cdMessage.uuid {
            dict[kPepID] = messageID as AnyObject
        }
        dict[kPepOutgoing] = NSNumber(booleanLiteral: outgoing)

        dict[kPepAttachments] = NSArray(
            array: (cdMessage.attachments?.array as? [CdAttachment] ?? []).map() {
                return pEpDict(cdAttachment: $0)
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
            { return pEpDict(cdIdentity: $0 as! CdIdentity) })

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

        return dict
    }

    /**
     Converts a typical core data set of CdIdentities into pEp identities.
     */
    open static func pEpIdentities(cdIdentitiesSet: NSOrderedSet?) -> [PEPIdentity]? {
        guard let cdIdentities = cdIdentitiesSet?.array as? [CdIdentity] else {
            return nil
        }
        return cdIdentities.map {
            return pEpDict(cdIdentity: $0)
        }
    }

    /**
     Converts a core data message into the format required by pEp.
     - Parameter message: The core data message to convert
     - Returns: A PEPMessage suitable for processing with pEp.
     */
    open static func pEp(cdMessage: CdMessage, outgoing: Bool = true) -> PEPMessage {
        let pEpMessage = PEPMessage()

        pEpMessage.sentDate = cdMessage.sent
        pEpMessage.shortMessage = cdMessage.shortMessage
        pEpMessage.longMessage = cdMessage.longMessage
        pEpMessage.longMessageFormatted = cdMessage.longMessageFormatted

        pEpMessage.to = pEpIdentities(cdIdentitiesSet: cdMessage.to)
        pEpMessage.cc = pEpIdentities(cdIdentitiesSet: cdMessage.cc)
        pEpMessage.bcc = pEpIdentities(cdIdentitiesSet: cdMessage.bcc)

        pEpMessage.from = pEpDict(cdIdentityOptional: cdMessage.from)
        pEpMessage.messageID = cdMessage.uuid
        pEpMessage.direction = outgoing ? PEP_dir_outgoing : PEP_dir_incoming

        if let cdAttachments = cdMessage.attachments?.array as? [CdAttachment] {
            pEpMessage.attachments = cdAttachments.map {
                return pEpDict(cdAttachment: $0)
            }
        }

        var refs = [String]()
        for ref in cdMessage.references?.array as? [CdMessageReference] ?? [] {
            if let refString = ref.reference {
                refs.append(refString)
            }
        }
        if !refs.isEmpty {
            pEpMessage.references = refs
        }

        var replyTos = [PEPIdentity]()
        if let r = cdMessage.replyTo {
            for ident in r.array {
                if let cdIdent = ident as? CdIdentity {
                    replyTos.append(cdIdent.pEpIdentity())
                }
            }
            if !replyTos.isEmpty {
                pEpMessage.replyTo = replyTos
            }
        }

        if let headerFields = cdMessage.optionalFields?.array as? [CdHeaderField] {
            var theFields = [(String, String)]()
            for field in headerFields {
                if let name = field.name, let value = field.value {
                    theFields.append((name, value))
                }
            }
            if !theFields.isEmpty {
                pEpMessage.optionalFields = theFields.map { (s1, s2) in
                    return [s1, s2]
                }
            }
        }

        return pEpMessage
    }

    /**
     For a PEPMessage, checks whether it is probably PGP/MIME encrypted.
     */
    open static func isProbablyPGPMime(pEpMessageDict: PEPMessageDict) -> Bool {
        guard let attachments = pEpMessageDict[kPepAttachments] as? NSArray else {
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
        return isProbablyPGPMime(pEpMessageDict: pEpDict(cdMessage: cdMessage))
    }

    /**
     Converts a pEp identity dict to a pantomime address.
     */
    open static func pantomime(pEpIdentity: PEPIdentity) -> CWInternetAddress {
        return CWInternetAddress(personal: pEpIdentity.userName, address: pEpIdentity.address)
    }

    /**
     Converts a list of pEp identities of a given receiver type to a list of pantomime recipients.
     */
    open static func pantomime(pEpIdentities: [PEPIdentity], recipientType: PantomimeRecipientType)
        -> [CWInternetAddress] {
            return pEpIdentities.map {
                let pant = pantomime(pEpIdentity: $0)
                pant.setType(recipientType)
                return pant
            }
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
        return pantomime(pEpMessageDict: pEpDict(cdMessage: cdMessage))
    }

    /**
     Converts a given `Message` into the equivalent `CWIMAPMessage`.
     */
    open static func pantomime(message: Message) -> CWIMAPMessage {
        return pantomime(pEpMessageDict: pEpDict(message: message))
    }

    open static func pantomime(pEpMessageDict: PEPMessageDict,
                               mailboxName: String? = nil) -> CWIMAPMessage {
        return CWIMAPMessage(pEpMessageDict: pEpMessageDict, mailboxName: mailboxName)
    }

    /**
     Extracts the body of a pEp mail as a pantomime part object.
     - Returns: Either a single CWPart,
     if there is only one text content (either pure text or HTML),
     or a "multipart/alternative" if there is both text and HTML,
     or nil.
     */
    static func bodyPart(pEpMessageDict: PEPMessageDict) -> CWPart? {
        let theBodyParts = bodyParts(pEpMessageDict: pEpMessageDict)
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
    static func bodyParts(pEpMessageDict: PEPMessageDict) -> [CWPart] {
        var parts: [CWPart] = []

        if let part = makePart(text: pEpMessageDict[kPepLongMessage] as? String,
                               contentType: Constants.contentTypeText) {
            parts.append(part)
        }
        if let part = makePart(text: pEpMessageDict[kPepLongMessageFormatted] as? String,
                               contentType: Constants.contentTypeHtml) {
            parts.append(part)
        }

        return parts
    }

    open static func pEpRating(cdIdentity: CdIdentity,
                               session: PEPSession = PEPSession()) -> PEP_rating {
        let pepC = pEpDict(cdIdentity: cdIdentity)
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

    open static func outgoingMessageColor(from: Identity, to: [Identity],
                                          cc: [Identity], bcc: [Identity],
                                          session: PEPSession = PEPSession()) -> PEP_rating {
        let msg = PEPMessage()
        msg.direction = PEP_dir_outgoing
        msg.from = from.pEpIdentity()
        let mapper: (Identity) -> PEPIdentity = { ident in
            return ident.pEpIdentity()
        }
        msg.to = to.map(mapper)
        msg.cc = cc.map(mapper)
        msg.bcc = bcc.map(mapper)
        msg.shortMessage = "short"
        msg.longMessage = "long"
        return session.outgoingColor(for: msg)
    }

    open static func pEpColor(identity: Identity,
                              session: PEPSession = PEPSession()) -> PEP_color {
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

    open static func fingerPrint(identity: Identity, session: PEPSession = PEPSession()) -> String? {
        let pEpID = pEp(identity: identity)
        session.update(pEpID)
        return pEpID.fingerPrint
    }

    open static func fingerPrint(cdIdentity: CdIdentity,
                                 session: PEPSession = PEPSession()) -> String? {
        let pEpID = pEpDict(cdIdentity: cdIdentity)
        session.update(pEpID)
        return pEpID.fingerPrint
    }

    /**
     Trust that contact (yellow to green).
     */
    open static func trust(identity: Identity, session: PEPSession = PEPSession()) {
        let pEpID = pEp(identity: identity)
        session.update(pEpID)
        session.trustPersonalKey(pEpID)
    }

    /**
     Mistrust the identity (yellow to red)
     */
    open static func mistrust(identity: Identity, session: PEPSession = PEPSession()) {
        let pEpID = pEp(identity: identity)
        session.update(pEpID)
        session.keyMistrusted(pEpID)
    }

    /**
     Resets the trust for the given `Identity`. Use both for trusting again after
     mistrusting a key, and for mistrusting a key after you have first trusted it.
     */
    open static func resetTrust(identity: Identity, session: PEPSession = PEPSession()) {
        let pEpID = pEp(identity: identity)
        session.update(pEpID)
        session.keyResetTrust(pEpID)
    }

    open static func encrypt(
        pEpMessageDict: PEPMessageDict, encryptionFormat: PEP_enc_format = PEP_enc_PEP,
        forIdentity: PEPIdentity? = nil,
        session: PEPSession = PEPSession()) -> (PEP_STATUS, NSDictionary?) {
        var encryptedMessage: NSDictionary? = nil

        if let ident = forIdentity {
            let pepStatus = session.encryptMessageDict(
                pEpMessageDict, identity: ident,
                dest: &encryptedMessage)
            return (pepStatus, encryptedMessage)
        } else {
            let pepStatus = session.encryptMessageDict(pEpMessageDict,
                                                       extra: nil,
                                                       encFormat: encryptionFormat,
                                                       dest: &encryptedMessage)
            return (pepStatus, encryptedMessage)
        }
    }

    open static func encrypt(
        pEpMessage: PEPMessage, forIdentity: PEPIdentity? = nil,
        session: PEPSession = PEPSession()) -> (PEP_STATUS, PEPMessage?) {
        var encryptedMessage: PEPMessage? = nil

        if let ident = forIdentity {
            let pepStatus = session.encryptMessage(
                pEpMessage, identity: ident,
                dest: &encryptedMessage)
            return (pepStatus, encryptedMessage)
        } else {
            let pepStatus = session.encryptMessage(
                pEpMessage, extra: nil,
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
                      encryptedMessage: NSDictionary?) -> (NSDictionary?, Error?) {
        if encryptedMessage != nil && status == PEP_UNENCRYPTED {
            // Don't interpret that as an error
            return (encryptedMessage, nil)
        }
        if encryptedMessage == nil || status != PEP_STATUS_OK {
            let error = BackgroundError.PepError.encryptionError(info: "\(comp)- status: \(status)")
            Log.error(component: comp,
                      error: BackgroundError.GeneralError.invalidParameter(info:
                        "Could not encrypt message, pEp status \(status)"))
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
    func pEpIdentity() -> PEPIdentityDict {
        var id = PEPIdentityDict()
        for (k, v) in self {
            if let ks = k as? String {
                id[ks] = v as AnyObject
            }
        }
        return id
    }
}
