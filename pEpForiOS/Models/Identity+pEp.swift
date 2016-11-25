//
//  Identity+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension Identity {
    public func pEpRating(session: PEPSession? = nil) -> PEP_rating {
        return PEPUtil.pEpRating(identity: self, session: session)
    }

    public func pEpColor(session: PEPSession? = nil) -> PEP_color {
        return PEPUtil.pEpColor(identity: self, session: session)
    }
}
