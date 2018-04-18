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

    /// - Returns: all attachments with mimeType "text/plain" and contentDisposition "inlined"
    func inlinedTextAttachments() -> [Attachment] {
        let result = attachments.filter() {
            return $0.isInlinedPlainText
        }
        return result
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

// MARK: - Handshake

/**
 Represents a combination of own identity and partner, on which the user can do
 a handshake action like:
 * trust
 * mistrust
 * ...
 */
public struct HandshakeCombination {
    let ownIdentity: Identity
    let partnerIdentity: Identity
}

extension Message {
    /**
     Determines all possible handshake combinations that the identies referenced in a message
     represent.
     */
    public func handshakeActionCombinations(
        session: PEPSession = PEPSession()) -> [HandshakeCombination] {
        let potentialIdentities = allIdentities

        let ownIdentities = potentialIdentities.filter() {
            $0.isMySelf
        }

        let ownIdentitiesWithKeys = ownIdentities.filter() {
            (try? $0.fingerPrint(session: session)) != nil
        }

        let partnerIdenties = potentialIdentities.filter() {
            $0.canInvokeHandshakeAction(session: session)
        }

        var handshakable = [HandshakeCombination]()
        for ownId in ownIdentitiesWithKeys {
            for partnerId in partnerIdenties {
                handshakable.append(HandshakeCombination(
                    ownIdentity: ownId, partnerIdentity: partnerId))
            }
        }

        return handshakable
    }
}
