//
//  CdAccount+KeySync.swift
//  MessageModel
//
//  Created by Andreas Buff on 18.11.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import CoreData
import PEPObjCAdapterFramework

extension CdAccount {

    func isKeySyncEnabled() throws -> Bool {//!!!: IOS-2325_!
        guard let user = identity else {
            Log.shared.errorAndCrash("No identity")
            return false
        }
        return try PEPSession().queryKeySyncEnabled(for: user.pEpIdentity()).boolValue//!!!: IOS-2325_!
    }

    func setKeySyncEnabled(enable: Bool) throws {//!!!: IOS-2325_!
        guard let user = identity  else {
            Log.shared.errorAndCrash("Invalid account")
            return
        }
        if enable {
            try PEPSession().enableSync(for: user.pEpIdentity())//!!!: IOS-2325_!
        } else {
            try PEPSession().disableSync(for: user.pEpIdentity())//!!!: IOS-2325_!
        }
    }
}
