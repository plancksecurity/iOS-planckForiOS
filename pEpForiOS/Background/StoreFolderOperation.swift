//
//  StoreFolderOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

struct FolderInfo {
    let name: String
    let separator: String
}

class StoreFolderOperation: ConcurrentBaseOperation {
    let comp = "StoreFolderOperation"
    let coreDataUtil: ICoreDataUtil
    let folderInfo: FolderInfo
    let email: String

    init(coreDataUtil: ICoreDataUtil, folderInfo: FolderInfo, email: String) {
        self.coreDataUtil = coreDataUtil
        self.folderInfo = folderInfo
        self.email = email
        super.init()
    }

    override func main() {
        let privateMOC = coreDataUtil.privateContext()
        privateMOC.performBlock({
            let model = Model.init(context: privateMOC)
            let folder = model.insertOrUpdateFolderName(
                self.folderInfo.name, accountEmail: self.email)
            if folder == nil {
                self.errors.append(Constants.errorCouldNotStoreFolder(self.comp,
                    name: self.folderInfo.name))
            }
            model.save()
            self.markAsFinished()
        })
    }
}