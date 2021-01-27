//
//  PrepareAccountForSavingService.swift
//  MessageModel
//
//  Created by Xavier Algarra on 26/06/2019.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

import PEPObjCAdapterFramework
import pEpIOSToolbox

public class PrepareAccountForSavingService {

    let fetchService = FetchImapFoldersService()

    public typealias Success = Bool

    public func prepareAccount(cdAccount: CdAccount,
                               pEpSyncEnable: Bool,
                               alsoCreatePEPFolder: Bool,
                               context: NSManagedObjectContext,
                               completion: @escaping (Success)->()) {
        // Generate Key
        guard let cdIdentity = cdAccount.identity else {
            Log.shared.errorAndCrash(message: "Impossible to get the identity")
            completion(false)
            return
        }
        KeyGeneratorService.generateKey(cdIdentity: cdIdentity,
                                        context: context,
                                        pEpSyncEnabled: pEpSyncEnable) { [weak self] (success) in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            guard success else {
                Log.shared.errorAndCrash("Error generating key")
                completion(success)
                return
            }
            // Assure folders exist
            me.fetchService.fetchFolders(inCdAccount: cdAccount,
                                         context: context,
                                         alsoCreatePEPFolder: alsoCreatePEPFolder,
                                         saveContextWhenDone: false,
                                         completion: completion)

        }
    }
}
