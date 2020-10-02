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
import pEpIOSToolbox

// MARK: - Internal

extension PEPUtils {
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

    /// Conversion from PEPRating raw value to PEPRating.
    /// - note: `i`MUST NOT be nil. Its only optional for convenience reasons, as CdO params are nullable.
    /// - Parameter i: raw value for PEPRating. MUST NOT be `nil`. Must be a valid value, i.e. an existing raw value of PEPRating.
    /// - Returns: PEPRating initialized with the given raw value. .undefined if the given value is invalid or nil.
    static func pEpRatingFromInt(_ rawValue: Int?) -> PEPRating {
        guard let theInt = rawValue else {
            Log.shared.errorAndCrash("Invalid int !")
            return .undefined
        }
        if theInt == PEPRating.undefined.rawValue {
            return .undefined
        }
        guard let ratingFromInt =  PEPRating(rawValue: Int32(theInt)) else {
            Log.shared.errorAndCrash("Invalid int !")
            return .undefined
        }
        return ratingFromInt
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
                                          contentType: MimeTypeUtils.MimeType.plainText.rawValue) {
            parts.append(part)
        }
        if let part = makeLongMessagePart(text: pEpMessage.longMessageFormatted,
                                          contentType: MimeTypeUtils.MimeType.html.rawValue) {
            parts.append(part)
        }

        return parts
    }
}
