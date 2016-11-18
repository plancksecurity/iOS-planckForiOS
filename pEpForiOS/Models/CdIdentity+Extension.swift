//
//  CdIdentity.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension CdIdentity {
    /**
     Converts a `PEPContact` to a dictionary suitable for `Record`'s creation methods.
     */
    open static func recordDictionary(pEpContact: PEPContact) -> [String: Any] {
        return [
            "address": pEpContact[kPepAddress] as Any,
            "userName": pEpContact[kPepUsername] as Any,
            "isMySelf": pEpContact[kPepIsMe] as? Bool ?? false]
    }

    /**
     Converts a `PEPContact`-like dictionary to a dictionary suitable
     for `Record`'s creation methods.
     */
    open static func recordDictionary(pEpDictionary: NSDictionary) -> [String: Any] {
        return [
            "address": pEpDictionary[kPepAddress] as Any,
            "userName": pEpDictionary[kPepUsername] as Any,
            "isMySelf": pEpDictionary[kPepIsMe] as? Bool ?? false]
    }

    open static func firstOrCreate(pEpContact: PEPContact) -> CdIdentity {
        let dict = recordDictionary(pEpContact: pEpContact)
        return CdIdentity.firstOrCreate(with: dict)
    }

    open static func firstOrCreate(dictionary: NSDictionary) -> CdIdentity {
        let dict = recordDictionary(pEpDictionary: dictionary)
        return CdIdentity.firstOrCreate(with: dict)
    }
}
