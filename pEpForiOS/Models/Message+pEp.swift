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

    public func pEpRating() -> PEP_rating? {
        return PEPUtil.pEpRatingFromInt(pEpRatingInt)
    }
}
