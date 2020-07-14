//
//  KeyGeneratorService.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 28/05/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapterFramework
import CoreData

struct KeyGeneratorService {

    /// Generate key for a cdIdentity
    ///
    /// - Parameters:
    ///   - cdIdentity:     identity (of account) to generate key for
    ///   - context:        context cdIdentity is safe to use on
    ///   - pEpSyncEnabled: whether or not to enable pEp Sync for this account
    static func generateKey(cdIdentity: CdIdentity,
                            context: NSManagedObjectContext,
                            pEpSyncEnabled: Bool) throws {//!!!: IOS-2325_!
        var pEpId : PEPIdentity?
        context.performAndWait {
            pEpId = cdIdentity.pEpIdentity()
        }
        guard let pEpIdentity = pEpId else {
            Log.shared.errorAndCrash(message: "No pEpId")
            return
        }

        let session = PEPSession()
        try session.mySelf(pEpIdentity)//!!!: IOS-2325_!

        if pEpSyncEnabled {
            try session.enableSync(for: pEpIdentity)//!!!: IOS-2325_!
        } else {
            try session.disableSync(for: pEpIdentity)//!!!: IOS-2325_!/15

        }
    }
}
