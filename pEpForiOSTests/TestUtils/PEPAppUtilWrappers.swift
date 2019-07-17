//
//  DuplicateExtensions.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 07.03.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import pEpForiOS
import PEPObjCAdapterFramework

// TODO: Duplicate.
extension CdIdentity {
    public func pEpIdentity() -> PEPIdentity {
        return PEPUtil.pEpDict(cdIdentity: self)
    }
}

// TODO: Duplicate.
extension PEPSession {
    public func encrypt(pEpMessageDict: PEPMessageDict,
                        encryptionFormat: PEPEncFormat = .PEP,
                        forSelf: PEPIdentity? = nil) throws -> (PEPStatus, NSDictionary?) {
        return try PEPUtil.encrypt(pEpMessageDict: pEpMessageDict,
                                   encryptionFormat: encryptionFormat,
                                   forSelf: forSelf)
    }
}
