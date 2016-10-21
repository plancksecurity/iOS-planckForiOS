//
//  CreateLocalSpecialFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 22/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

open class CreateLocalSpecialFoldersOperation: BaseOperation {
    let comp = "CreateLocalSpecialFoldersOperation"
    let coreDataUtil: CoreDataUtil
    let accountEmail: String

    public init(coreDataUtil: CoreDataUtil, accountEmail: String) {
        self.coreDataUtil = coreDataUtil
        self.accountEmail = accountEmail
        super.init()
    }

    open override func main() {
        let privateMOC = coreDataUtil.privateContext()
        privateMOC.performAndWait({
            let model = CdModel.init(context: privateMOC)
            for kind in FolderType.allValuesToCreate {
                let folderName = kind.folderName()
                if let folder = model.insertOrUpdateFolderName(
                    folderName, folderSeparator: nil, accountEmail: self.accountEmail) {
                    folder.folderType = NSNumber(value: kind.rawValue)
                } else  {
                    self.addError(Constants.errorCouldNotStoreFolder(self.comp,
                        name: folderName))
                }
            }
            model.save()
        })
    }
}
