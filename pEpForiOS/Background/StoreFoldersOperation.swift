//
//  StoreFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

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
        let privateMOC = grandOperator.coreDataUtil.privateContext()
        privateMOC.performBlockAndWait({
            let model = Model.init(context: privateMOC)
            for folderName in self.foldersToStore {
                let folder = model.insertOrUpdateFolderName(
                    folderName, accountEmail: self.email)
                if folder == nil {
                    self.errors.append(Constants.errorCouldNotStoreFolder(self.comp,
                        name: folderName))
                }
            }
            model.save()
        })
    }
}