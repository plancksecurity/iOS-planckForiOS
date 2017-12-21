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
