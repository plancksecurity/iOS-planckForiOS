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
    var accountObjectID: NSManagedObjectID {
        var result = NSManagedObjectID()
        MessageModel.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            guard let cdAccount = CdAccount.search(account: me.account) else {
                Log.shared.errorAndCrash(component: #function, errorString: "No CdAccount")
                return

            }
            result = cdAccount.objectID
        }
        return result
    }

    @available(*, deprecated, message: "use server instead")
    var serverObjectID: NSManagedObjectID {
        var result = NSManagedObjectID()
        MessageModel.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            let serverType = me.server.serverType
            guard
                let cdAccount = CdAccount.search(account: me.account),
                let cdServer = cdAccount.server(type: serverType) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No CdAccount")
                    return
            }
            result = cdServer.objectID
        }
        return result
    }

    @available(*, deprecated, message: "use credentials instead")
    var credentialsObjectID: NSManagedObjectID {
        var result = NSManagedObjectID()
        MessageModel.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "Lost myself")
                return
            }
            let serverType = me.server.serverType
            guard
                let cdAccount = CdAccount.search(account: me.account),
                let cdServer = cdAccount.server(type: serverType),
                let cdCredentials = cdServer.credentials else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No CdAccount")
                    // Return garbage
                    return
            }

            result = cdCredentials.objectID
        }
        return result
    }
}

extension EmailConnectInfo {
    @available(*, deprecated, message: "use credentials instead")
    func folderBy(name: String, context: NSManagedObjectContext) throws -> CdFolder {
        guard let cdAccount = context.object(with: accountObjectID) as? CdAccount else {
            throw BackgroundError.CoreDataError.couldNotFindAccount(info: #function)
        }
        guard let cdFolder = CdFolder.by(name: name, account: cdAccount, context: context) else {
            throw BackgroundError.CoreDataError.couldNotFindFolder(info: #function)
        }
        return cdFolder
    }
}
