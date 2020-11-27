//
//  Identity+pEpIdentity.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 13.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

extension Identity {
    func pEpIdentity() -> PEPIdentity {
        return cdObject.pEpIdentity()
    }
}
