//
//  CdIdentity+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 22/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

/**
 pEp extension for CdIdentity
 */
extension CdIdentity {
    public func pEpRating(session: PEPSession = PEPSession()) -> PEPRating {
        let pepC = PEPUtil.pEpDict(cdIdentity: self)
        do {
            return try session.rating(for: pepC).pEpRating
        } catch let error as NSError {
            assertionFailure("\(error)")
            return .undefined
        }
    }

    public func pEpColor(session: PEPSession = PEPSession()) -> PEPColor {
        let rating = self.pEpRating(session: session)
        return session.color(from: rating)
    }

    public func fingerPrint(session: PEPSession = PEPSession()) throws -> String? {
        return try PEPUtil.fingerPrint(cdIdentity: self, session: session)
    }
}
