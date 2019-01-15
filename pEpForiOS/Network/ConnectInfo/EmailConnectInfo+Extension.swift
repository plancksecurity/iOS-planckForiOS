//
//  EmailConnectInfo+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

extension EmailConnectInfo {

    func folderBy(name: String) throws -> Folder? {
        var cdResult: CdFolder?
        var error: Error?
        MessageModel.performAndWait { [weak self] in
            guard let me = self else {
                Logger.frontendLogger.lostMySelf()
                return
            }
            let context = Record.Context.background
            guard
                let accountId = me.accountObjectID,
                let cdAccount = context.object(with: accountId) as? CdAccount else {
                    error = BackgroundError.CoreDataError.couldNotFindAccount(info: #function)
                    return
            }
            guard
                let cdFolder = CdFolder.by(name: name, account: cdAccount, context: context) else {
                    error = BackgroundError.CoreDataError.couldNotFindFolder(info: #function)
                    return
            }
            cdResult = cdFolder
        }
        if let error = error {
            throw error
        }
        return cdResult?.folder()
    }

}
