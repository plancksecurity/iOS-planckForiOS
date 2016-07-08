//
//  CreateLocalSpecialFoldersOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 22/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit

public class CreateLocalSpecialFoldersOperation: BaseOperation {
    let comp = "CreateLocalSpecialFoldersOperation"
    let coreDataUtil: ICoreDataUtil
    let accountEmail: String

    public init(coreDataUtil: ICoreDataUtil, accountEmail: String) {
        self.coreDataUtil = coreDataUtil
        self.accountEmail = accountEmail
        super.init()
    }

    public override func main() {
        let privateMOC = coreDataUtil.privateContext()
        privateMOC.performBlockAndWait({
            let model = Model.init(context: privateMOC)
            for kind in FolderType.allValuesToCreate {
                let folderName = kind.folderName()
                if var folder = model.insertOrUpdateFolderName(folderName,
                    accountEmail: self.accountEmail) {
                    folder.folderType = kind.rawValue
                } else  {
                    self.addError(Constants.errorCouldNotStoreFolder(self.comp,
                        name: folderName))
                }
            }
            model.save()
        })
    }
}
