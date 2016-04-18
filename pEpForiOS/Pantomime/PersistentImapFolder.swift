//
//  PersistentImapFolder.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

class PersistentImapFolder: CWIMAPFolder {
    let connectInfo: ConnectInfo
    let context: NSManagedObjectContext

    init(name: String, connectInfo: ConnectInfo, context: NSManagedObjectContext) {
        self.connectInfo = connectInfo
        self.context = context
        super.init(name: name)
    }

    override func allMessages() -> [AnyObject] {
        let p = NSPredicate.init(format: "folder.account.email = %@ and folder.name = %@", connectInfo.email,
                                 self.name())
        if let messages = Message.entitiesWithName(Message.entityName(), predicate: p,
                                                   context: context) {
            return messages
        } else {
            return []
        }
    }
}