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
    public static func from(pEpContact: PEPContact?) -> CdIdentity? {
        guard let pEpC = pEpContact else {
            return nil
        }
        guard let addr = pEpC[kPepAddress] as? String else {
            return nil
        }
        let ident = CdIdentity.create()
        ident.address = addr
        ident.userName = pEpC[kPepUsername] as? String
        if let mySelfNum = pEpC[kPepIsMe] as? NSNumber {
            ident.isMySelf = mySelfNum
        }
        if let ctNum = pEpC[kPepCommType] as? NSNumber {
            ident.commType = ctNum
        }
        ident.userID = pEpC[kPepUserID] as? String
        return ident
    }

    public static func from(pEpContacts: [PEPContact]?) -> [CdIdentity] {
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
}
