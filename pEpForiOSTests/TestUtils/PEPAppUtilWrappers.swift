//
//  DuplicateExtensions.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 07.03.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
@testable import pEpForiOS

// TODO: Duplicate.
public extension CdIdentity {
    public func pEpIdentity() -> PEPIdentity {
        return PEPAppUtil.pEpDict(cdIdentity: self)
    }
}

// TODO: Duplicate.
public extension PEPSession {
    public func encrypt(pEpMessageDict: PEPMessageDict,
                        encryptionFormat: PEPEncFormat = .PEP,
                        forSelf: PEPIdentity? = nil) throws -> (PEPStatus, NSDictionary?) {
        return try PEPAppUtil.encrypt(
            pEpMessageDict: pEpMessageDict, encryptionFormat: encryptionFormat,
            forSelf: forSelf, session: self)
    }
}
