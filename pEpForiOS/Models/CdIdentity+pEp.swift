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
        return PEPUtil.pEpRating(cdIdentity: self, session: session)
    }

    public func pEpColor(session: PEPSession = PEPSession()) -> PEPColor {
        return PEPUtil.pEpColor(cdIdentity: self, session: session)
    }

    public func fingerPrint(session: PEPSession = PEPSession()) throws -> String? {
        return try PEPUtil.fingerPrint(cdIdentity: self, session: session)
    }
}
