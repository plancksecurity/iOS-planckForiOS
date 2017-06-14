//
//  NSMutableDictionary+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25.04.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension NSMutableDictionary {
    public var commType: PEP_comm_type? {
        if let val = object(forKey: kPepCommType) as? NSNumber {
            return PEP_comm_type(val.uint32Value)
        }
        return nil
    }

    public var isPGP: Bool {
        let ct = commType ?? PEP_ct_unknown
        switch ct {
        case PEP_ct_OpenPGP_weak_unconfirmed, PEP_ct_OpenPGP_unconfirmed,
             PEP_ct_OpenPGP_weak, PEP_ct_OpenPGP:
            return true
        default:
            return false
        }
    }

    public var isConfirmed: Bool {
        let ct = commType ?? PEP_ct_unknown
        return (ct.rawValue & PEP_ct_confirmed.rawValue) > 0
    }

    /**
     Assumes that this dictionary contains a pEp identity and calls
     `updateIdentity` on the given session.
     */
    public func update(session: PEPSession) {
        session.updateIdentity(self)
    }
}
