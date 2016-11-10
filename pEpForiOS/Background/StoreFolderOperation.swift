//
//  StoreFolderOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

struct FolderInfo {
    let name: String
    let separator: String
}

class StoreFolderOperation: ConcurrentBaseOperation {
    let comp = "StoreFolderOperation"
    let folderInfo: FolderInfo
    let email: String

    init(coreDataUtil: CoreDataUtil, folderInfo: FolderInfo, email: String) {
        self.folderInfo = folderInfo
        self.email = email
    }

    override func main() {
        let privateMOC = coreDataUtil.privateContext()
        privateMOC.perform({
            let model = CdModel.init(context: privateMOC)
            let folder = model.insertOrUpdateFolderName(
                self.folderInfo.name, folderSeparator: self.folderInfo.separator,
                accountEmail: self.email)
            if folder == nil {
                self.errors.append(Constants.errorCouldNotStoreFolder(self.comp,
                    name: self.folderInfo.name))
            }
            model.save()
            self.markAsFinished()
        })
    }
}
