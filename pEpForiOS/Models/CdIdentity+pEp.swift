//
//  CdIdentity+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 22/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel

/**
 pEp extension for CdIdentity
 */
extension CdIdentity {
    public static func from(pEpContact: PEPIdentityDict?) -> CdIdentity? {
        guard let pEpC = pEpContact else {
            return nil
        }
        guard let addr = pEpC[kPepAddress] as? String else {
            return nil
        }

        let userName = pEpC[kPepUsername] as? String
        let userID = pEpC[kPepUserID] as? String

        var identity: Identity
        if let existing = Identity.by(address: addr) {
            identity = existing
            if !identity.isMySelf {
                identity.userName = userName
            }
        } else {
            // this identity has to be created
            identity = Identity.create(address: addr, userID: userID, userName: userName)
        }
        identity.save()

        guard let result = CdIdentity.search(address: addr) else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString: "We have just saved this identity. It has to exist.")
            return CdIdentity.create()
        }

        return result
    }

    public static func from(pEpContacts: [PEPIdentityDict]?) -> [CdIdentity] {
        let theContacts = pEpContacts ?? []
        var contacts = [CdIdentity]()
        for p in theContacts {
            if let c = from(pEpContact: p) {
                contacts.append(c)
            }
        }
        return contacts
    }

    public func pEpRating(session: PEPSession = PEPSession()) -> PEP_rating {
        return PEPUtil.pEpRating(cdIdentity: self, session: session)
    }

    public func pEpColor(session: PEPSession = PEPSession()) -> PEP_color {
        return PEPUtil.pEpColor(cdIdentity: self, session: session)
    }

    public func pEpIdentity() -> PEPIdentityDict {
        return PEPUtil.pEp(cdIdentity: self)
    }

    public func fingerPrint(session: PEPSession = PEPSession()) -> String? {
        return PEPUtil.fingerPrint(cdIdentity: self, session: session)
    }
}
