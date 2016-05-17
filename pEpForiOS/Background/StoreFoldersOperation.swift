//
//  StoreFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

class StoreFoldersOperation: BaseOperation {
    let comp = "StoreFoldersOperation"
    let foldersToStore: [String]
    let email: String

    init(grandOperator: IGrandOperator, folders: [String], email: String) {
        self.foldersToStore = folders
        self.email = email
        super.init(grandOperator: grandOperator)
    }

    override func main() {
        Log.warn(comp, "StoreFoldersOperation started")
        let model = grandOperator.operationModel()
        for folderName in foldersToStore {
            let folder = model.insertOrUpdateFolderName(
                folderName, folderType: Account.AccountType.Imap, accountEmail: email)
            if folder == nil {
                grandOperator.setErrorForOperation(
                    self,
                    error: Constants.errorCouldNotStoreFolder(comp, name: folderName))
            }
        }
        model.save()
        Log.warn(comp, "StoreFoldersOperation finished")
    }
}