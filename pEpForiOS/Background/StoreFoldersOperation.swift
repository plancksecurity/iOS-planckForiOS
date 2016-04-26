//
//  StoreFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

class StoreFoldersOperation: BaseOperation {

    let foldersToStore: [String]
    let email: String

    init(grandOperator: IGrandOperator, folders: [String], email: String) {
        self.foldersToStore = folders
        self.email = email
        super.init(grandOperator: grandOperator)
    }

    override func main() {
        let context = grandOperator.coreDataUtil.confinedManagedObjectContext()
        for folderName in foldersToStore {
            do {
            try Folder.insertOrUpdateFolderWithName(folderName,
                                                    folderType: Account.AccountType.Imap,
                                                    accountEmail: email,
                                                    context: context)
            } catch let err as NSError {
                grandOperator.setErrorForOperation(self, error: err)
            }
        }
        CoreDataUtil.saveContext(managedObjectContext: context)
    }
}