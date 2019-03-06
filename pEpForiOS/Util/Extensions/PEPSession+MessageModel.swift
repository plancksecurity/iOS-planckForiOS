//
//  PEPSession+MessageModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 06.03.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import PEPObjCAdapterFramework

extension PEPSession {
    /**
     Calculates the outgoing message rating for a hypothetical mail.
     - Returns: The message rating, or .Undefined in case of any error.
     - Note: TODO: This is a duplicate of an extension method in MessageModel that
     apparently can't be accessed due do name-mangling problems with swiftc.
     */
    func outgoingMessageRating(from: Identity, to: [Identity],
                               cc: [Identity], bcc: [Identity]) -> PEPRating {
        let msg = PEPMessage()
        msg.direction = .outgoing
        msg.from = from.pEpIdentity()
        let mapper: (Identity) -> PEPIdentity = { ident in
            return ident.pEpIdentity()
        }
        msg.to = to.map(mapper)
        msg.cc = cc.map(mapper)
        msg.bcc = bcc.map(mapper)
        msg.shortMessage = "short"
        msg.longMessage = "long"
        do {
            return try outgoingRating(for: msg).pEpRating
        } catch let error as NSError {
            assertionFailure("\(error)")
            return .undefined
        }
    }
}
