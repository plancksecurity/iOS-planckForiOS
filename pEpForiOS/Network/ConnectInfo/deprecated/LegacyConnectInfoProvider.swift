//
//  LegacyConnectInfoProvider.swift
//  pEp
//
//  Created by Andreas Buff on 23.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel
import CoreData

/// Supports usage of deprecated EmailConnectInfo.
extension ConnectInfo {
    @available(*, deprecated, message: "use account instead")
    var accountObjectID: NSManagedObjectID? {
        var result: NSManagedObjectID? = nil
        MessageModel.performAndWait { [weak self] in
            guard let me = self else {
                Logger.lostMySelf(category: Logger.frontend)
                return
            }
            guard let cdAccount = CdAccount.search(account: me.account) else {
                Logger(category: Logger.util).errorAndCrash("No CdAccount")
                return
            }
            result = cdAccount.objectID
        }
        return result
    }

    @available(*, deprecated, message: "use server instead")
    var serverObjectID: NSManagedObjectID? {
        var result: NSManagedObjectID? = nil
        MessageModel.performAndWait { [weak self] in
            guard let me = self else {
                Logger.lostMySelf(category: Logger.frontend)
                return
            }
            let serverType = me.server.serverType
            guard
                let cdAccount = CdAccount.search(account: me.account),
                let cdServer = cdAccount.server(type: serverType) else {
                    Logger(category: Logger.util).errorAndCrash("No CdAccount")
                    return
            }
            result = cdServer.objectID
        }
        return result
    }
}

extension EmailConnectInfo {

    @available(*, deprecated, message: "use folderBy(name:) instead")
    func folderBy(name: String, context: NSManagedObjectContext) throws -> CdFolder {
        guard
            let accountId = accountObjectID,
            let cdAccount = context.object(with: accountId) as? CdAccount else {
                throw BackgroundError.CoreDataError.couldNotFindAccount(info: #function)
        }
        guard let cdFolder = CdFolder.by(name: name, account: cdAccount, context: context) else {
            throw BackgroundError.CoreDataError.couldNotFindFolder(info: #function)
        }
        return cdFolder
    }
}
