//
//  SendMailOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 23/06/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

class SendMailOperation: BaseOperation {
    let comp = "SendMailOperation"

    let coreDataUtil: ICoreDataUtil
    let messageID: NSManagedObjectID
    let accountEmail: String

    init(coreDataUtil: ICoreDataUtil, messageID: NSManagedObjectID, accountEmail: String) {
        self.coreDataUtil = coreDataUtil
        self.messageID = messageID
        self.accountEmail = accountEmail
        super.init()
    }

    convenience init(coreDataUtil: ICoreDataUtil, message: Message) {
        self.init(coreDataUtil: coreDataUtil, messageID: message.objectID,
                  accountEmail: message.folder.account.email)
    }

    override func main() {
        let privateMOC = coreDataUtil.privateContext()
        privateMOC.performBlockAndWait({
            let model = Model.init(context: privateMOC)
            guard let message = privateMOC.objectWithID(self.messageID) as? Message else {
                Log.warn(self.comp, "Need valid email")
                return
            }
            guard let account = model.accountByEmail(self.accountEmail) else {
                Log.warn(self.comp, "Need valid account")
                return
            }
            guard let folder = model.folderLocalOutboxForEmail(self.accountEmail) as? Folder else {
                Log.warn(self.comp, "Need account with local outbox folder")
                return
            }
            message.folder = folder
            model.save()
        })
    }
}