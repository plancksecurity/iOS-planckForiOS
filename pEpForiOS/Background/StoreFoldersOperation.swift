//
//  StoreFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

class StoreFoldersOperation: ConcurrentBaseOperation {
    let comp = "StoreFoldersOperation"
    let coreDataUtil: ICoreDataUtil
    let foldersToStore: [String]
    let email: String

    init(coreDataUtil: ICoreDataUtil, folders: [String], email: String) {
        self.coreDataUtil = coreDataUtil
        self.foldersToStore = folders
        self.email = email
        super.init()
    }

    override func main() {
        let privateMOC = coreDataUtil.privateContext()
        privateMOC.performBlock({
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
            self.markAsFinished()
        })
    }
}