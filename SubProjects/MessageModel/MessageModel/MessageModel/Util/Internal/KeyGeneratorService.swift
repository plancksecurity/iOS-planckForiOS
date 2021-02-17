//
//  KeyGeneratorService.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 28/05/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS

#if EXT_SHARE
import PEPIOSToolboxForAppExtensions
#else
import pEpIOSToolbox
#endif

struct KeyGeneratorService {

    /// Generate key for a new, own cdIdentity.
    ///
    /// - Parameters:
    ///   - cdIdentity:     identity (of account) to generate key for
    ///   - context:        context cdIdentity is safe to use on
    ///   - pEpSyncEnabled: whether or not to enable pEp Sync for this account
    ///   - completion: called when done. `success`is false in case an error occured.
    static func generateKey(cdIdentity: CdIdentity,
                            context: NSManagedObjectContext,
                            pEpSyncEnabled: Bool,
                            completion: @escaping (Success) -> ()) {
        let queue = DispatchQueue(label: "\(#file)-\(#function)", qos: .userInitiated)
        queue.async {
            var pEpId : PEPIdentity?
            context.performAndWait {
                pEpId = cdIdentity.pEpIdentity()
            }
            guard var pEpIdentity = pEpId else {
                Log.shared.errorAndCrash(message: "No pEpId")
                completion(false)
                return
            }
            var success = true
            let group = DispatchGroup()
            group.enter()
            PEPSession().mySelf(pEpIdentity, errorCallback: { (_) in
                success = false
                group.leave()
            }) { (updatedIdentity) in
                pEpIdentity = updatedIdentity
                group.leave()
            }
            group.wait()
            if !success {
                completion(success)
                return
            }

            if pEpSyncEnabled {
                PEPSession().enableSync(for: pEpIdentity,
                                             errorCallback: { _ in
                                                completion(false)
                }) {
                    completion(true)
                }
            } else {
                PEPSession().disableSync(for: pEpIdentity,
                                              errorCallback: { _ in
                                                completion(false)
                }) {
                    completion(true)
                }
            }
        }
    }
}
