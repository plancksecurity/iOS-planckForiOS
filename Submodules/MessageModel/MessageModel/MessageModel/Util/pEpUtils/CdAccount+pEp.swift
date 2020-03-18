//
//  CdAccount+pEp.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 25/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import PEPObjCAdapterFramework
import pEpIOSToolbox

//!!!: MUST be internal
extension CdAccount {
    open func pEpIdentity() -> PEPIdentity {
        return PEPUtils.pEpIdentity(for: self)
    }

    public func server(with type: Server.ServerType) -> CdServer? {
        guard let servs = servers?.allObjects as? [CdServer] else {
            return nil
        }

        let serversForType = servs.filter { $0.serverType == type }
        if serversForType.count == 0 {
            return nil
        }
        if serversForType.count > 1 {
            Log.shared.errorAndCrash(
                "No servers of type %d for IMAP account %@",
                type.rawValue, identity?.address ?? "nil")
        }
        return serversForType.first
    }
}
