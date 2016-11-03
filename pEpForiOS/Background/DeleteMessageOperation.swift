//
//  DeleteMessageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

open class DeleteMessageOperation: ConcurrentBaseOperation {
    let messageID: NSManagedObjectID

    //public init(message: MessageModelConfig.)
    
    
    
    public init(message: CdMessage, coreDataUtil: CoreDataUtil) {
        
        self.messageID = message.objectID
        super.init(coreDataUtil: coreDataUtil)
    }

    override open func main() {
        let bg = Record.Context.background
        bg.perform {
            guard let message = bg.object(with: self.messageID) as? CdMessage
                else {
                    return
            }
            
            
            var targetFolder: CdFolder?
            // XXX: To refactor properly.
            targetFolder = self.model.folderByType(.trash, account: self.model.accountByEmail("")!)
            if targetFolder == nil {
                // XXX: To refactor properly.
                targetFolder = self.model.folderByType(.archive, account: self.model.accountByEmail("")!)
            }
            
            guard let folder = targetFolder else {
                // TODO: Just delete the mail
                self.markAsFinished()
                return
            }
            
            let cwMail = PEPUtil.pantomimeMailFromMessage(message)
            let cwFolder = CWIMAPFolder.init(name: folder.name!)
            cwFolder.copyMessages([cwMail], toFolder: cwFolder.name())
        }
        
    }
}
