//
//  PEPUtils.swift
//  pEpForiOS
//
//  Created by hernani on 13/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData
import PantomimeFramework
import PEPObjCAdapterFramework

// MARK: - Internal

extension PEPUtils {

    static func add(pEpIdentities: [PEPIdentity], toPantomimeMessage: CWIMAPMessage,
                    recipientType: PantomimeRecipientType) {
        let addresses = pantomime(
            pEpIdentities: pEpIdentities, recipientType: recipientType)
        for a in addresses {
            toPantomimeMessage.addRecipient(a)
        }
    }

    /// Converts a given `CdMessage` into the equivalent `CWIMAPMessage`.
    static func pantomime(cdMessage: CdMessage) -> CWIMAPMessage {
        return pantomime(pEpMessage: cdMessage.pEpMessage())
    }

    static func pantomime(pEpMessage: PEPMessage,
                          mailboxName: String? = nil) -> CWIMAPMessage {
        return CWIMAPMessage(pEpMessage: pEpMessage, mailboxName: mailboxName)
    }

    static func bodyPart(pEpMessage: PEPMessage) -> CWPart? {
        let theBodyParts = bodyParts(pEpMessage: pEpMessage)
        if theBodyParts.count == 1 {
            return theBodyParts[0]
        } else if theBodyParts.count > 1 {
            let partAlt = CWPart()
            partAlt.setContentType(ContentTypeUtils.ContentType.multipartAlternative)
            let partMulti = CWMIMEMultipart()
            for part in theBodyParts {
                partMulti.add(part)
            }
            partAlt.setContent(partMulti)
            return partAlt
        }
        return nil
    }

    static func pEpRatingFromInt(_ i: Int?) -> PEPRating? {
        guard let theInt = i else {
            return nil
        }
        if theInt == PEPRating.undefined.rawValue {
            return .undefined
        }
        return PEPRating(rawValue: Int32(theInt))
    }

    static func pEpColor(cdIdentity: CdIdentity,
                         context: NSManagedObjectContext = Stack.shared.mainContext,
                         completion: @escaping (PEPColor) -> Void) {
        pEpRating(cdIdentity: cdIdentity, context: context) { (rating) in
            completion(rating.pEpRating().pEpColor())
        }
    }

    static func pEpColor(pEpRating: PEPRating?) -> PEPColor {
        if let rating = pEpRating {
            return PEPSession().color(from: rating)
        } else {
            return PEPColor.noColor
        }
    }
}

// MARK: - Private

extension PEPUtils {

    /// Converts a list of pEp identities of a given receiver type to a list of pantomime recipients.
    private static func pantomime(pEpIdentities: [PEPIdentity],
                                  recipientType: PantomimeRecipientType) -> [CWInternetAddress] {
        return pEpIdentities.map {
            let pant = $0.internetAddress()
            pant.setType(recipientType)
            return pant
        }
    }

    /// Converts the given long message (may be HTML) into a pantomime part.
    ///
    /// The content will be encoded (base64), to avoid exceeding MIME line length limits.
    ///
    /// - Parameters:
    ///   - text: The text (plain or HTML) to be put into the body.
    ///   - contentType: The wanted content type (e.g. ContentTypeUtils.ContentType.plainText,
    ///                  or ContentTypeUtils.ContentType.html).
    /// - Returns: The CWPart if text is not nil, nil otherwise.
    static private func makeLongMessagePart(text: String?, contentType: String) -> CWPart? {
        if let t = text {
            let part = CWPart()
            part.setContentType(contentType)
            part.setContent(t.data(using: String.Encoding.utf8) as NSObject?)
            part.setCharset("UTF-8")
            part.setContentTransferEncoding(PantomimeEncodingBase64)
            return part
        }
        return nil
    }

    static private func bodyParts(pEpMessage: PEPMessage) -> [CWPart] {
        var parts: [CWPart] = []

        if let part = makeLongMessagePart(text: pEpMessage.longMessage,
                                          contentType: ContentTypeUtils.ContentType.plainText) {
            parts.append(part)
        }
        if let part = makeLongMessagePart(text: pEpMessage.longMessageFormatted,
                                          contentType: ContentTypeUtils.ContentType.html) {
            parts.append(part)
        }

        return parts
    }
}
