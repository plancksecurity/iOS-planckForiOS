//
//  CreateLocalRequiredFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 22/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

open class CreateLocalRequiredFoldersOperation: BaseOperation {
    let accountObjectID: NSManagedObjectID

    public init(parentName: String, account: CdAccount) {
        accountObjectID = account.objectID
        super.init(parentName: parentName)
    }

    open override func main() {
        let privateMOC = Record.Context.default
        privateMOC.performAndWait({
            self.createFolders(context: privateMOC)
        })
    }

    func createFolders(context: NSManagedObjectContext) {
        guard let account = context.object(with: accountObjectID)
            as? CdAccount else {
                addError(Constants.errorCannotFindAccount(component: comp))
                return
        }
        for kind in FolderType.allValuesToCreate {
            let folderName = kind.folderName()
            if let (folder, _) = CdFolder.insertOrUpdate(
                folderName: folderName, folderSeparator: nil, account: account) {
                folder.folderType = Int16(kind.rawValue)
            } else  {
                self.addError(Constants.errorCouldNotStoreFolder(self.comp,
                                                                 name: folderName))
            }
        }
        context.saveAndLogErrors()
    }
}
