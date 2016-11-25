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

    /**
     Converts a `PEPIdentity` to a dictionary suitable for `Record`'s creation methods.
     */
    public static func recordDictionary(pEpContact: PEPIdentity) -> [String: Any] {
        return [
            "address": pEpContact[kPepAddress] as Any,
            "userName": pEpContact[kPepUsername] as Any,
            "isMySelf": pEpContact[kPepIsMe] as? Bool ?? false]
    }

    /**
     Converts a `PEPIdentity`-like dictionary to a dictionary suitable
     for `Record`'s creation methods.
     */
    public static func recordDictionary(pEpDictionary: NSDictionary) -> [String: Any] {
        return [
            "address": pEpDictionary[kPepAddress] as Any,
            "userName": pEpDictionary[kPepUsername] as Any,
            "isMySelf": pEpDictionary[kPepIsMe] as? Bool ?? false]
    }

    public static func firstOrCreate(pEpContact: PEPIdentity) -> CdIdentity {
        let dict = recordDictionary(pEpContact: pEpContact)
        return CdIdentity.firstOrCreate(with: dict)
    }

    public static func firstOrCreate(dictionary: NSDictionary) -> CdIdentity {
        let dict = recordDictionary(pEpDictionary: dictionary)
        return CdIdentity.firstOrCreate(with: dict)
    }

    public func pEpRating(session: PEPSession? = nil) -> PEP_rating {
        return PEPUtil.pEpRating(cdIdentity: self, session: session)
    }

    public func pEpColor(session: PEPSession? = nil) -> PEP_color {
        return PEPUtil.pEpColor(cdIdentity: self, session: session)
    }

    public func pEpIdentity(cdIdentity: CdIdentity) -> PEPIdentity {
        return PEPUtil.pEp(cdIdentity: self)
    }
}
