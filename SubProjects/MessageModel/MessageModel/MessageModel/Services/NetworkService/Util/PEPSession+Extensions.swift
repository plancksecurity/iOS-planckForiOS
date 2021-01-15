//
//  PEPSession+Extensions.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework
import pEpIOSToolbox

// MARK: - Useful extensions for PEPSession

extension PEPAsyncSession {
    func outgoingMessageRating(from: Identity,
                               to: [Identity],
                               cc: [Identity],
                               bcc: [Identity],
                               completion: @escaping (PEPRating) -> Void) {
        let mapper: (Identity) -> CdIdentity = { ident in
            return ident.cdObject
        }
        outgoingMessageRating(from: from.cdObject,
                              to: to.map(mapper),
                              cc: cc.map(mapper),
                              bcc: bcc.map(mapper),
                              completion: completion)
    }
}

// MARK: - Private

extension PEPAsyncSession {


    private func outgoingMessageRating(from: CdIdentity,
                                       to: [CdIdentity],
                                       cc: [CdIdentity],
                                       bcc: [CdIdentity],
                                       completion: @escaping (PEPRating)->Void) {
        let mapper: (CdIdentity) -> PEPIdentity = { cdIdent in
            return cdIdent.pEpIdentity()
        }
        outgoingMessageRating(from: from.pEpIdentity(),
                              to: to.map(mapper),
                              cc: cc.map(mapper),
                              bcc: bcc.map(mapper),
                              completion: completion)
    }

    /// Calculates the outgoing message rating for a hypothetical mail.
    /// - Returns: The message rating, or .Undefined in case of any error.
    private func outgoingMessageRating(from: PEPIdentity,
                                       to: [PEPIdentity],
                                       cc: [PEPIdentity],
                                       bcc: [PEPIdentity],
                                       completion: @escaping (PEPRating)->Void) {
        let msg = PEPMessage()
        msg.direction = .outgoing
        msg.from = from
        msg.to = to
        msg.cc = cc
        msg.bcc = bcc
        msg.shortMessage = "short"
        msg.longMessage = "long"
        outgoingRating(for: msg, errorCallback: { (error) in
            Log.shared.errorAndCrash(error: error)
            completion(.undefined)
        }) { (rating) in
            completion(rating)
        }
    }
}
