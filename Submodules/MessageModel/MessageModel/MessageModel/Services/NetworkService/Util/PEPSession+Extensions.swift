//
//  PEPSession+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework

// MARK: - Useful extensions for PEPSession

extension PEPSession {

    /// Calculates the outgoing message rating for a hypothetical mail.
    /// - Returns: The message rating, or .Undefined in case of any error.
    public func outgoingMessageRating(from: PEPIdentity, to: [PEPIdentity],//!!!: IOS-2325_!
                                      cc: [PEPIdentity], bcc: [PEPIdentity]) -> PEPRating {
        let msg = PEPMessage()
        msg.direction = .outgoing
        msg.from = from
        msg.to = to
        msg.cc = cc
        msg.bcc = bcc
        msg.shortMessage = "short"
        msg.longMessage = "long"
        do {
            return try outgoingRating(for: msg).pEpRating//!!!: IOS-2325_!
        } catch let error as NSError {
            assertionFailure("\(error)")
            return .undefined
        }
    }

    public func outgoingMessageRating(from: Identity, to: [Identity],//!!!: IOS-2325_!
                                      cc: [Identity], bcc: [Identity]) -> PEPRating {
        let mapper: (Identity) -> PEPIdentity = { ident in
            return ident.pEpIdentity()
        }
        return outgoingMessageRating(from: from.pEpIdentity(),//!!!: IOS-2325_!
                                     to: to.map(mapper),
                                     cc: cc.map(mapper),
                                     bcc: bcc.map(mapper))
    }

    public func outgoingMessageRating(from: CdIdentity, to: [CdIdentity],
                                      cc: [CdIdentity], bcc: [CdIdentity]) -> PEPRating {
        let mapper: (CdIdentity) -> PEPIdentity = { cdIdent in
            return cdIdent.pEpIdentity()
        }

        return outgoingMessageRating(//!!!: IOS-2325_!
            from: from.pEpIdentity(), to: to.map(mapper), cc: cc.map(mapper), bcc: bcc.map(mapper))
    }
}
