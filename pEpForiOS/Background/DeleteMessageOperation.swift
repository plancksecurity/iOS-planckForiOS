//
//  DeleteMessageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

open class DeleteMessageOperation: ConcurrentBaseOperation {
    let messageID: NSManagedObjectID

    public init(message: CdMessage, coreDataUtil: ICoreDataUtil) {
        self.messageID = message.objectID
        super.init(coreDataUtil: coreDataUtil)
    }

    override open func main() {
        privateMOC.perform({
            guard let message = self.privateMOC.object(with: self.messageID) as?
                CdMessage
                else {
                    return
            }

            var targetFolder: CdFolder?
            targetFolder = self.model.folderByType(.trash, account: message.folder.account)
            if targetFolder == nil {
                targetFolder = self.model.folderByType(
                    .archive, account: message.folder.account)
            }

            guard let folder = targetFolder else {
                // TODO: Just delete the mail
                self.markAsFinished()
                return
            }

            let cwMail = PEPUtil.pantomimeMailFromMessage(message)
            let cwFolder = CWIMAPFolder.init(name: folder.name)
            cwFolder.copyMessages([cwMail], toFolder: cwFolder.name())
        })
    }
}
