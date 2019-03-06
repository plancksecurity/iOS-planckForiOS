//
//  CdAccount+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import MessageModel
import pEpIOSToolbox

extension CdAccount {
    open func pEpIdentity() -> PEPIdentity {
        if let id = self.identity {
            return pEpDict(cdIdentity: id)
        } else {
            Logger.utilLogger.errorAndCrash(
                "account without identity: %{public}@", account)
            return PEPIdentity(address: "none")
        }
    }
}
