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
    let accountEmail: String

    public init(grandOperator: IGrandOperator, accountEmail: String) {
        self.accountEmail = accountEmail
        super.init(grandOperator: grandOperator)
    }

    public override func main() {
        let privateMOC = grandOperator.coreDataUtil.privateContext()
        privateMOC.performBlockAndWait({
            let model = Model.init(context: privateMOC)
            for kind in FolderType.allValuesToCreate {
                let folderName = kind.folderName()
                let folder = model.insertOrUpdateFolderName(folderName,
                    accountEmail: self.accountEmail)
                if folder == nil {
                    self.errors.append(Constants.errorCouldNotStoreFolder(self.comp,
                        name: folderName))
                }
            }
            model.save()
        })
    }
}
