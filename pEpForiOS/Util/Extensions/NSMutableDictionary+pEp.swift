//
//  NSMutableDictionary+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension NSMutableDictionary {
    /**
     Assumes that this dictionary contains a pEp identity and calls
     `updateIdentity` on the given session.
     */
    public func update(session: PEPSession) -> NSMutableDictionary {
        session.updateIdentity(self)
        return self
    }
}
