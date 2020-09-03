//
//  Message+Extension.swift
//  MessageModel
//
//  Created by Martin Brude on 14/02/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapterFramework

extension Message {

    /// Indicates if the message has been processed by the engine.
    public var isEncrypted: Bool {
        return PEPUtils.pEpRatingFromInt(self.pEpRatingInt) == .undefined
    }

    /// Persists the original rating header to the current message.
    /// - Parameter rating: The PEPRating to be set.
    public func setOriginalRatingHeader(rating: PEPRating) {
        setOriginalRatingHeader(rating: rating.asString())
    }

    /// - returns: the pepRating
    public func pEpRating(completion: @escaping (PEPRating)->Void) {
        //see: https://dev.pep.security/Common%20App%20Documentation/algorithms/MessageColors
        if session.moc == Session.main.moc {
            return  Message.pEpRating(message: self, completion: completion)
        } else {
            return  Message.pEpRating(message: self, session: session, completion: completion)
        }
    }

    /// - returns: the pepColor
    public func pEpColor(completion: @escaping (PEPColor)->Void) {
        pEpRating { (rating) in
            completion(rating.pEpColor())
        }
    }

    /// - returns: All the attachments that must be shown to the user
    public func viewableAttachments() -> [Attachment] {
        guard ratingIsOkToShowAttachments else {
            return []
        }
        return attachments.filter() { $0.isViewable() }
    }

    /// - returns: all attachments with mimeType "text/plain" and contentDisposition "inlined"
    public func inlinedTextAttachments() -> [Attachment] {
        let result = attachments.filter() { $0.isInlinedPlainText }
        return result
    }
}
