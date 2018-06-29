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
        return pEpRating(session: session).pEpColor()
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
    static public func allMessagesMarkedForMoveToFolder(inAccount account: Account) -> [Message] {
        let predicateInAccount =
            CdMessage.PredicateFactory.belongingToAccountWithAddress(address: account.user.address)
        let predicateMarkedForMove = CdMessage.PredicateFactory.markedForMoveToFolder()
        let predicates = NSCompoundPredicate(andPredicateWithSubpredicates: [predicateInAccount,
                                                                             predicateMarkedForMove])
        let cdMessages = CdMessage.all(predicate: predicates) as? [CdMessage] ?? []
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
    public let ownIdentity: Identity
    public let partnerIdentity: Identity
}

extension Message {
    /**
     Given a list of identities (typically those involved in a message),
     figures out a list of own identity <-> partner identity combinations that
     one can handshake on.
     - Returns: A list of `HandshakeCombination`s.
     */
    public static func handshakeActionCombinations<T>(
        session: PEPSession = PEPSession(),
        identities: T) -> [HandshakeCombination]
        where T: Collection, T.Element: Identity {
        let ownIdentities = identities.filter() {
            $0.isMySelf
        }

        let ownIdentitiesWithKeys = ownIdentities.filter() {
            (try? $0.fingerPrint(session: session)) != nil
        }

        let partnerIdenties = identities.filter() {
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

    /**
     Determines all possible handshake combinations that the identies referenced in a message
     represent.
     */
    public func handshakeActionCombinations(
        session: PEPSession = PEPSession()) -> [HandshakeCombination] {
        return Message.handshakeActionCombinations(session: session, identities: allIdentities)
    }
}
