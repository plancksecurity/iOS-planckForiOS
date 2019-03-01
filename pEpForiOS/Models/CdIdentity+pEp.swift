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
    public static func from(pEpContact: PEPIdentity?) -> CdIdentity? {
        guard let pEpC = pEpContact else {
            return nil
        }
        var identity: Identity
        if let existing = Identity.by(address: pEpC.address) {
            identity = existing
            if !identity.isMySelf {
                identity.userName = pEpC.userName
            }
        } else {
            // this identity has to be created
            identity = Identity.create(address: pEpC.address, userID: pEpC.userID,
                                       userName: pEpC.userName)
        }
        identity.save()

        guard let result = CdIdentity.search(address: pEpC.address) else {
            Logger.modelLogger.errorAndCrash(
                "We have just saved this identity. It has to exist.")
            return CdIdentity.create()
        }

        return result
    }

    public static func from(pEpContacts: [PEPIdentity]?) -> [CdIdentity] {
        let theContacts = pEpContacts ?? []
        var contacts = [CdIdentity]()
        for p in theContacts {
            if let c = from(pEpContact: p) {
                contacts.append(c)
            }
        }
        return contacts
    }

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
