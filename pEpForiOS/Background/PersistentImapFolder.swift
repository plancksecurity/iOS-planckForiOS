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
    let comp = "PersistentImapFolder"

    let mainContext: NSManagedObjectContext
    let connectInfo: ConnectInfo
    let backgroundQueue: NSOperationQueue
    let grandOperator: GrandOperator
    let cache: PersistentEmailCache

    init(name: String, grandOperator: GrandOperator, connectInfo: ConnectInfo,
         backgroundQueue: NSOperationQueue) {
        self.connectInfo = connectInfo
        self.backgroundQueue = backgroundQueue
        self.grandOperator = grandOperator
        self.mainContext = grandOperator.coreDataUtil.managedObjectContext
        self.cache = PersistentEmailCache.init(grandOperator: grandOperator,
                                               connectInfo: connectInfo,
                                               backgroundQueue: backgroundQueue)
        super.init(name: name)
        self.setCacheManager(cache)
    }

    func predicateAllMessages() -> NSPredicate {
        let p = NSPredicate.init(format: "folder.account.email = %@ and folder.name = %@",
                                 connectInfo.email,
                                 self.name())
        return p
    }

    /**
     - Note: This must always be called from the main thread. As called by Pantomime, this should
     be the case.
     */
    override func allMessages() -> [AnyObject] {
        if let messages = Message.entitiesWithName(Message.entityName(),
                                                   predicate: self.predicateAllMessages(),
                                                   context: mainContext) {
            return messages
        } else {
            return []
        }
    }

    override func count() -> UInt {
        let n = Message.countWithName(Message.entityName(), predicate: self.predicateAllMessages(),
                                      context: mainContext)
        return UInt(n)
    }
}