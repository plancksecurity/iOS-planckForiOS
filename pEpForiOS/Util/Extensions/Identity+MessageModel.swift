//
//  Identity+MessageModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 06.03.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import PEPObjCAdapterFramework

extension Identity {
    /**
     - Note: TODO: This is a duplicate of an extension method in MessageModel that
     apparently can't be accessed due do name-mangling problems with swiftc.
     PEPUtil.pEp(identity: Identity) -> PEPIdentity
     */
    public func pEp() -> PEPIdentity {
        return PEPIdentity(
            address: self.address, userID: self.userID, userName: self.userName,
            isOwn: self.isMySelf, fingerPrint: nil,
            commType: PEPCommType.unknown, language: nil)
    }
}
