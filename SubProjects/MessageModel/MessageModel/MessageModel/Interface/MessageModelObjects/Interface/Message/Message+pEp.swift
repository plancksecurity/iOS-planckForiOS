//
//  Message+pEp.swift
//  MessageModel
//
//  Created by Martin Brude on 14/02/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension Message {

    /// Persists the original rating header to the current message.
    /// - Parameter rating: The PEPRating to be set.
    public func setOriginalRatingHeader(rating: Rating) {
        setOriginalRatingHeader(rating: rating.toString())
    }

    /// - returns: the pepRating
    public func pEpRating(completion: @escaping (Rating) -> Void) {
        //see: https://dev.pep.security/Common%20App%20Documentation/algorithms/MessageColors
        if session.moc == Session.main.moc {
            return Message.pEpRating(message: self) { pEpRating in
                completion(Rating(pEpRating: pEpRating))
            }
        } else {
            return  Message.pEpRating(message: self, session: session) { pEpRating in
                completion(Rating(pEpRating: pEpRating))
            }
        }
    }

    /// - returns: All the attachments that must be shown to the user
    public func viewableAttachments() -> [Attachment] {
        guard ratingIsOkToShowAttachments else {
            return []
        }
        return attachments.filter() { $0.isViewable() }
    }

    /// - returns: all attachments that are images. 
    public var viewableImageAttachments: [Attachment] {
        return viewableAttachments().filter{ $0.isInlined && $0.fileName != nil && !$0.isCidContained }
    }

    /// - returns: all attachments with mimeType "text/plain" and contentDisposition "inlined"
    public func inlinedTextAttachments() -> [Attachment] {
        let result = attachments.filter() { $0.isInlinedPlainText }
        return result
    }

    /// - returns: all viewable attachments non inlined with file name
    public var viewableNotInlinedAttachments: [Attachment] {
        return viewableAttachments().filter{ !$0.isInlined && $0.fileName != nil && !$0.isCidContained }
    }

    /// - returns: All the attachments that must be shown to the user
    public func icsAttachments() -> [Attachment] {
        return attachments.filter { $0.isICS }
    }
}
