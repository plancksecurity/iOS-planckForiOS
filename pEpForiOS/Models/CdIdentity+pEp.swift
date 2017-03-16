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
    public static func from(pEpContact: PEPIdentity?) -> CdIdentity? {
        guard let pEpC = pEpContact else {
            return nil
        }
        guard let addr = pEpC[kPepAddress] as? String else {
            return nil
        }
        var identOpt = CdIdentity.search(address: addr)
        if identOpt == nil {
            identOpt = CdIdentity.create()
        }
        if let theIdent = identOpt {
            theIdent.userName = pEpC[kPepUsername] as? String
            if let mySelfNum = pEpC[kPepIsMe] as? NSNumber {
                theIdent.isMySelf = mySelfNum
            }
            if let ctNum = pEpC[kPepCommType] as? NSNumber {
                theIdent.commType = ctNum
            }
            theIdent.userID = pEpC[kPepUserID] as? String
            Record.saveAndWait()
            return theIdent
        }
        return nil
    }

    public static func from(pEpContacts: [PEPIdentity]?) -> [CdIdentity] {
        guard let theContacts = pEpContacts else {
            return []
        }
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

    public func pEpIdentity() -> PEPIdentity {
        return PEPUtil.pEp(cdIdentity: self)
    }

    public func fingerPrint(session: PEPSession = PEPSession()) -> String? {
        return PEPUtil.fingerPrint(cdIdentity: self, session: session)
    }
}
