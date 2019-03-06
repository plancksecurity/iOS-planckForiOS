//
//  PEPUtil.swift
//  pEp
//
//  Created by Dirk Zimmermann on 06.03.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox
import PantomimeFramework
import PEPObjCAdapterFramework
import MessageModel

public class PEPUtil {
    static let comp = "PEPUtil"

    /**
     Default pEpRating value when there's none, i.e. the message has never been decrypted.
     */
    public static let pEpRatingNone = CdMessage.pEpRatingNone

    /**
     Content type for MIME multipart/alternative.
     */
    public static let kMimeTypeMultipartAlternative = "multipart/alternative"

    /** Delete pEp working data. */
    public static func pEpClean() -> Bool {
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

    public static func identity(account: CdAccount) -> PEPIdentity {
        if let id = account.identity {
            return pEpDict(cdIdentity: id)
        } else {
            Logger.utilLogger.errorAndCrash(
                "account without identity: %{public}@", account)
            return PEPIdentity(address: "none")
        }
    }

    public static func pEp(identity: Identity) -> PEPIdentity {
        return PEPIdentity(
            address: identity.address, userID: identity.userID, userName: identity.userName,
            isOwn: identity.isMySelf, fingerPrint: nil,
            commType: PEPCommType.unknown, language: nil)
    }

    /**
     Like the corresponding `pEpDict(cdIdentity)`, but dealing with optional parameters.
     */
    public static func pEpDict(cdIdentityOptional: CdIdentity?) -> PEPIdentity? {
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
    public static func pEpDict(cdIdentity: CdIdentity) -> PEPIdentity {
        if let address = cdIdentity.address {
            return PEPIdentity(address: address, userID: cdIdentity.userID,
                               userName: cdIdentity.userName, isOwn: cdIdentity.isMySelf,
                               fingerPrint: nil, commType: PEPCommType.unknown, language: nil)
        } else {
            Logger.utilLogger.errorAndCrash(
                "missing address: %{public}@", cdIdentity)
            return PEPIdentity(address: "none")
        }
    }

    /**
     Creates pEp contact just from name and address.
     */
    public static func pEpIdentity(email: String, name: String) -> PEPIdentityDict {
        var identity = PEPIdentityDict()
        identity[kPepAddress] = email as AnyObject
        identity[kPepUsername] = name as AnyObject
        return identity
    }

    public static func pEpOptional(identity: Identity?) -> PEPIdentity? {
        guard let id = identity else {
            return nil
        }
        return pEp(identity: id)
    }

    public static func pEpAttachment(
        fileName: String?, mimeType: String?, data: Data?,
        contentDispositionType: PEPContentDisposition) -> PEPAttachment {
        let attachment = PEPAttachment(data: data ?? Data())
        attachment.filename = fileName
        attachment.mimeType = mimeType
        attachment.contentDisposition = contentDispositionType
        return attachment
    }

    /**
     Converts a `CdAttachment` into a PEPAttachment.
     */
    public static func pEpAttachment(cdAttachment: CdAttachment) -> PEPAttachment {
        let contentDispoType = PEPContentDisposition(rawValue:
            Int(cdAttachment.contentDispositionTypeRawValue))
        if contentDispoType == nil {
            Logger.backendLogger.errorAndCrash(
                "Unsupported PEPContentDisposition %d",
                cdAttachment.contentDispositionTypeRawValue)
        }
        return pEpAttachment(fileName: cdAttachment.fileName,
                             mimeType: cdAttachment.mimeType,
                             data: cdAttachment.data as Data?,
                             contentDispositionType: contentDispoType ?? .attachment)
    }

    /**
     Converts a `Attachment` into a PEPAttachment.
     */
    public static func pEpAttachment(attachment: Attachment) -> PEPAttachment {
        let contentDispoType = PEPContentDisposition(rawValue:
            Int(attachment.contentDisposition.rawValue))
        if contentDispoType == nil {
            Logger.backendLogger.errorAndCrash(
                "Unsupported PEPContentDisposition %d",
                attachment.contentDisposition.rawValue)
        }
        return pEpAttachment(fileName: attachment.fileName,
                             mimeType: attachment.mimeType,
                             data: attachment.data as Data?,
                             contentDispositionType: contentDispoType ?? .attachment)
    }

    /**
     Converts a core data message into the format required by pEp.
     - Parameter message: The core data message to convert
     - Returns: An object (`NSMutableDictionary`) suitable for processing with pEp.
     */
    public static func pEpDict(cdMessage: CdMessage, outgoing: Bool = true) -> PEPMessageDict {
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

        let theAttachments = NSArray(
            array: (cdMessage.attachments?.array as? [CdAttachment] ?? []).map() {
                return pEpAttachment(cdAttachment: $0)
        })
        dict[kPepAttachments] = theAttachments

        var refs = [String]()
        for ref in cdMessage.references?.array as? [CdMessageReference] ?? [] {
            if let refString = ref.reference {
                refs.append(refString)
            }
        }

        if refs.count > 0 {
            dict[kPepReferences] = refs as AnyObject
        }

        if let replyTos = cdMessage.replyTo, replyTos.count > 0 {
            dict[kPepReplyTo] = NSArray(array: replyTos
                .map { pEpDict(cdIdentity: $0 as! CdIdentity) })
        }

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
    public static func pEpIdentities(cdIdentitiesSet: NSOrderedSet?) -> [PEPIdentity]? {
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
    public static func pEp(cdMessage: CdMessage, outgoing: Bool = true) -> PEPMessage {
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
        pEpMessage.direction = outgoing ? .outgoing : .incoming

        if let cdAttachments = cdMessage.attachments?.array as? [CdAttachment] {
            pEpMessage.attachments = cdAttachments.map {
                return pEpAttachment(cdAttachment: $0)
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
    public static func isProbablyPGPMime(pEpMessageDict: PEPMessageDict) -> Bool {
        guard let attachments = pEpMessageDict[kPepAttachments] as? NSArray else {
            return false
        }

        var foundAttachmentPGPEncrypted = false
        for atch in attachments {
            guard let at = atch as? PEPAttachment else {
                continue
            }
            guard let filename = at.mimeType else {
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
    public static func isProbablyPGPMime(cdMessage: CdMessage) -> Bool {
        return isProbablyPGPMime(pEpMessageDict: pEpDict(cdMessage: cdMessage))
    }

    /**
     Converts a pEp identity dict to a pantomime address.
     */
    public static func pantomime(pEpIdentity: PEPIdentity) -> CWInternetAddress {
        return CWInternetAddress(personal: pEpIdentity.userName, address: pEpIdentity.address)
    }

    /**
     Converts a list of pEp identities of a given receiver type to a list of pantomime recipients.
     */
    public static func pantomime(pEpIdentities: [PEPIdentity], recipientType: PantomimeRecipientType)
        -> [CWInternetAddress] {
            return pEpIdentities.map {
                let pant = pantomime(pEpIdentity: $0)
                pant.setType(recipientType)
                return pant
            }
    }

    public static func add(pEpIdentities: [PEPIdentity], toPantomimeMessage: CWIMAPMessage,
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
    public static func pantomime(cdMessage: CdMessage) -> CWIMAPMessage {
        return pantomime(pEpMessageDict: pEpDict(cdMessage: cdMessage))
    }

    public static func pantomime(pEpMessageDict: PEPMessageDict,
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

    public static func pEpRating(cdIdentity: CdIdentity,
                                 session: PEPSession = PEPSession()) -> PEPRating {
        let pepC = pEpDict(cdIdentity: cdIdentity)
        do {
            return try session.rating(for: pepC).pEpRating
        } catch let error as NSError {
            assertionFailure("\(error)")
            return .undefined
        }
    }

    public static func pEpColor(cdIdentity: CdIdentity,
                                session: PEPSession = PEPSession()) -> PEPColor {
        return pEpColor(pEpRating: pEpRating(cdIdentity: cdIdentity, session: session))
    }

    public static func pEpRating(identity: Identity,
                                 session: PEPSession = PEPSession()) -> PEPRating {
        let pepC = pEp(identity: identity)
        do {
            return try session.rating(for: pepC).pEpRating
        } catch {
            Logger.utilLogger.errorAndCrash(
                "Identity: %{public}@ caused error: %{public}@",
                identity.description, error.localizedDescription)
            return .undefined
        }
    }

    public static func pEpColor(identity: Identity,
                                session: PEPSession = PEPSession()) -> PEPColor {
        return pEpColor(pEpRating: pEpRating(identity: identity, session: session))
    }

    public static func pEpColor(pEpRating: PEPRating?,
                                session: PEPSession = PEPSession()) -> PEPColor {
        if let rating = pEpRating {
            return session.color(from: rating)
        } else {
            return PEPColor.noColor
        }
    }

    public static func pEpRatingFromInt(_ i: Int?) -> PEPRating? {
        guard let theInt = i else {
            return nil
        }
        if theInt == Int(pEpRatingNone) {
            return .undefined
        }
        return PEPRating(rawValue: theInt)
    }

    /**
     Uses the adapter's update to determine the fingerprint of the given identity.
     - Note: Also works for own identities without triggering key generation.
     */
    public static func fingerPrint(identity: Identity, session: PEPSession = PEPSession()) throws
        -> String? {
            let pEpID = pEp(identity: identity)
            if pEpID.isOwn {
                // If we have an own identity, avoid a call to myself by nulling userID
                pEpID.userID = nil
                pEpID.isOwn = false
            }
            try session.update(pEpID)
            return pEpID.fingerPrint
    }

    public static func fingerPrint(cdIdentity: CdIdentity,
                                   session: PEPSession = PEPSession()) throws -> String? {
        if let theID = cdIdentity.identity() {
            return try fingerPrint(identity: theID, session: session)
        } else {
            return nil
        }
    }

    /**
     Trust that contact (yellow to green).
     */
    public static func trust(identity: Identity, session: PEPSession = PEPSession()) throws {
        let pEpID = pEp(identity: identity)
        try session.update(pEpID)
        try session.trustPersonalKey(pEpID)
    }

    /**
     Mistrust the identity (yellow to red)
     */
    public static func mistrust(identity: Identity, session: PEPSession = PEPSession()) throws {
        let pEpID = pEp(identity: identity)
        try session.update(pEpID)
        try session.keyMistrusted(pEpID)
    }

    /**
     Resets the trust for the given `Identity`. Use both for trusting again after
     mistrusting a key, and for mistrusting a key after you have first trusted it.
     */
    public static func resetTrust(identity: Identity, session: PEPSession = PEPSession()) throws {
        let pEpID = pEp(identity: identity)
        try session.update(pEpID)
        try session.keyResetTrust(pEpID)
    }

    public static func encrypt(
        pEpMessageDict: PEPMessageDict, encryptionFormat: PEPEncFormat = .PEP,
        forSelf: PEPIdentity? = nil,
        extraKeys: [String]? = nil,
        session: PEPSession = PEPSession()) throws -> (PEPStatus, NSDictionary?) {

        var status = PEPStatus.unknownError
        if let ident = forSelf {
            let encryptedMessage = try session.encryptMessageDict(
                pEpMessageDict,
                forSelf: ident,
                extraKeys: extraKeys,
                status: &status) as NSDictionary
            return (status, encryptedMessage)
        } else {
            let encMessage = try session.encryptMessageDict(
                pEpMessageDict,
                extraKeys: nil,
                encFormat: encryptionFormat,
                status: &status) as NSDictionary
            return (status, encMessage)
        }
    }

    public static func encrypt(
        pEpMessage: PEPMessage,
        forSelf: PEPIdentity? = nil,
        extraKeys: [String]? = nil,
        session: PEPSession = PEPSession()) throws -> (PEPStatus, PEPMessage?) {

        var status = PEPStatus.unknownError
        if let ident = forSelf {
            let encryptedMessage = try session.encryptMessage(
                pEpMessage,
                forSelf: ident,
                extraKeys: extraKeys,
                status: &status)
            return (status, encryptedMessage)
        } else {
            let encMessage = try session.encryptMessage(pEpMessage,
                                                        extraKeys: nil,
                                                        status: &status)
            return (status, encMessage)
        }
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
        let bottom = NSLocalizedString("sent with p≡p",
                                       comment: "pEp mail signature. Newlines will be added by app")
        return "\n\n\(bottom)\n"
    }

    static var pEpSignatureHtml: String {
        let pEpSignatureTrimmed = String.pepSignature.trimmed()
        return "<a href=\"https://pep.software/withiOS\" style=\"color:\(UIColor.pEpDarkGreenHex); text-decoration: none;\">\(pEpSignatureTrimmed)</a>"
    }

    public func replacingOccurrencesOfPepSignatureWithHtmlVersion() -> String {
        let pEpSignatureTrimmed = String.pepSignature.trimmed()
        return replacingOccurrences(of: pEpSignatureTrimmed, with: String.pEpSignatureHtml)
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
