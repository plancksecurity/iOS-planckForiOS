//
//  StoreFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

class StoreFoldersOperation: NSOperation {

    let grandOperator: GrandOperator
    let foldersToStore: [String]
    let email: String

    init(grandOperator: GrandOperator, folders: [String], email: String) {
        self.grandOperator = grandOperator
        self.foldersToStore = folders
        self.email = email
    }

    override func main() {
        let context = grandOperator.coreDataUtil.confinedManagedObjectContext()
        for folderName in foldersToStore {
            Account.insertOrUpdateFolderWithName(folderName, folderType: Account.AccountType.Imap,
                                                 accountEmail: email,
                                                 context: context)
        }
        CoreDataUtil.saveContext(managedObjectContext: context)
    }
}