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

public class PrepareAccountForSavingService {

    let fetchService = FetchImapFoldersService()

    public typealias Success = Bool

    public func prepareAccount(cdAccount: CdAccount,//!!!: IOS-2325_!
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
        do {
            try KeyGeneratorService.generateKey(cdIdentity: cdIdentity,//!!!: IOS-2325_!
                                                context: context,
                                                pEpSyncEnabled: pEpSyncEnable)
        } catch {
            Log.shared.errorAndCrash(error: error)
            completion(false)
            return
        }
        
        // Assure folders exist
        fetchService.fetchFolders(inCdAccount: cdAccount,
                                  context: context,
                                  alsoCreatePEPFolder: alsoCreatePEPFolder,
                                  saveContextWhenDone: false) { success in
                                    completion(success)

        }
    }
}
