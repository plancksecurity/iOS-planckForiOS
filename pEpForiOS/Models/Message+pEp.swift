//
//  Message+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

extension Message {
    public func pEpMessage(message: Message, outgoing: Bool = true) -> PEPMessage {
        return PEPUtil.pEp(message: self)
    }

    public func pEpRating(session: PEPSession?) -> PEP_rating? {
        if belongToSentFolder() {
            return Message.calculateOutgoingColorFromMessage(message: self)
        } else {
            return PEPUtil.pEpRatingFromInt(pEpRatingInt)
        }
    }

    func belongToSentFolder() -> Bool {
        if self.parent?.folderType  == FolderType.sent {
            return true
        } else {
            return false
        }
    }

    static func calculateOutgoingColorFromMessage(message: Message) -> PEP_rating? {
        if let from = message.from {
            return PEPUtil.outgoingMessageColor(from: from, to: message.to,
                                                      cc: message.cc, bcc: message.bcc)
        }
        return nil
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
    func viewableAttachments() -> [Attachment] {
        return attachments.filter() { att in
            if att.data == nil || att.mimeType.lowercased() == "application/pgp-keys" {
                return false
            }
            if att.mimeType.lowercased() == "image/gif" {
                return false
            }
            return true
        }
    }
}
