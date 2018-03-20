//
//  Message+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Message {
    public var isEncrypted: Bool {
        return PEPUtil.pEpRatingFromInt(self.pEpRatingInt) == PEP_rating_undefined
    }

    public func pEpMessageDict(outgoing: Bool = true) -> PEPMessageDict {
        return PEPUtil.pEpDict(message: self)
    }

    public func pEpRating(session: PEPSession = PEPSession()) -> PEP_rating {
        if belongToSentFolder() || belongToDraftFolder () || belongToTrashFolder() {
            if let original = self.optionalFields[Headers.originalRating.rawValue] {
                return session.rating(from: original)
            }
            return PEP_rating_undefined
        } else {
            return PEPUtil.pEpRatingFromInt(pEpRatingInt) ?? PEP_rating_undefined
        }
    }

    public func pEpColor(session: PEPSession = PEPSession()) -> PEP_color {
        return pEpRating(session: session).pepColor()
    }

    func belongToSentFolder() -> Bool {
        return self.parent.folderType == FolderType.sent
    }
    
    func belongToDraftFolder() -> Bool {
        return self.parent.folderType == FolderType.drafts
    }

    func belongToTrashFolder() -> Bool {
        return self.parent.folderType == FolderType.trash
    }

    /**
     - Returns: An array of identities you can make a handshake on.
     */
    public func identitiesEligibleForHandshake(session: PEPSession = PEPSession()) -> [Identity] {
        let myselfIdentity = PEPUtil.ownIdentity(message: self)
        return Array(allIdentities).filter {
            return $0 != myselfIdentity && $0.canHandshakeOn(session: session)
        }
    }

    /**
     - Returns: An array of attachments that can be viewed.
     */
    public func viewableAttachments() -> [Attachment] {
        let viewable = attachments.filter() { return $0.isViewable() }
        let parentMessageAssured = viewable.map { attachment -> (Attachment) in
            attachment.message = self
            return attachment
        }
        
        return parentMessageAssured
    }
}

// MARK: - Fetching

extension Message {

    /// - Returns: all messages marked for UidMoveToTrash
    static public func allMessagesMarkedForUidExpunge() -> [Message] {
        let predicateMarkedUidExpunge = CdMessage.PredicateFactory.markedForUidMoveToTrash()
        let cdMessages = CdMessage.all(predicate: predicateMarkedUidExpunge) as? [CdMessage] ?? []
        var result = [Message]()
        for cdMessage in cdMessages {
            guard let message = cdMessage.message() else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "No Message for CdMesssage")
                continue
            }
            result.append(message)
        }
        return result
    }
}
