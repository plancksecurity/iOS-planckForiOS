//
//  CdAccount+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension CdAccount {
    open func pEpIdentity() -> PEPIdentity {
        return PEPUtil.identity(account: self)
    }
}
