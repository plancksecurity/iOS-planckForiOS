//
//  PEPIdentity+Pantomime.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework
import PEPObjCAdapterFramework

extension PEPIdentity {
    /// Converts a pEp identity dict to a pantomime address.
    func cwInternetAddress() -> CWInternetAddress {
        return CWInternetAddress(personal: userName, address: address)
    }
}
