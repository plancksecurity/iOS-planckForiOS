//
//  DeleteMessageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

open class DeleteMessageOperation: ConcurrentBaseOperation {
    let comp = "DeleteMessageOperation"
    let messageID: NSManagedObjectID

    public init(message: MessageModel.CdMessage, coreDataUtil: CoreDataUtil) {
        self.messageID = message.objectID
    }

    override open func main() {
        privateMOC.perform {
            guard let message = self.privateMOC.object(with: self.messageID) as? MessageModel.CdMessage else {
                return
            }

            let pred = NSPredicate(format: "folderType = %d or folderType = %d",
                                   FolderType.trash.rawValue, FolderType.archive.rawValue)
            guard let targetFolder = MessageModel.CdFolder.first(with: pred) else {
                Log.error(component: self.comp, errorString: "No trash folder defined")
                return
            }
            message.parent = targetFolder

            // Mark the message, so it can be retried?
            message.uid = 0

            let cwMail = PEPUtil.pantomimeMailFromMessage(message)
            let cwFolder = CWIMAPFolder.init(name: targetFolder.name!)
            cwFolder.copyMessages([cwMail], toFolder: cwFolder.name())
        }
        
    }
}
