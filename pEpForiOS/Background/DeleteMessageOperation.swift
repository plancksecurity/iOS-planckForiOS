//
//  DeleteMessageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

public class DeleteMessageOperation: ConcurrentBaseOperation {
    let messageID: NSManagedObjectID

    public init(message: IMessage, coreDataUtil: ICoreDataUtil) {
        self.messageID = (message as! Message).objectID
        super.init(coreDataUtil: coreDataUtil)
    }

    override public func main() {
        privateMOC.performBlock({
            guard let message = self.privateMOC.objectWithID(self.messageID) as?
                IMessage
                else {
                    return
            }

            var targetFolder: IFolder?
            targetFolder = self.model.folderByType(.Trash, account: message.folder.account)
            if targetFolder == nil {
                targetFolder = self.model.folderByType(
                    .Archive, account: message.folder.account)
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