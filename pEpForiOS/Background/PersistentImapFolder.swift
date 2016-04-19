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

    let connectInfo: ConnectInfo
    let context: NSManagedObjectContext
    let backgroundQueue: NSOperationQueue
    let grandOperator: GrandOperator
    let watchedMessages: NSMutableOrderedSet = []
    var cache: PersistentEmailCache!

    init(name: String, grandOperator: GrandOperator, connectInfo: ConnectInfo,
         backgroundQueue: NSOperationQueue) {
        self.connectInfo = connectInfo
        self.backgroundQueue = backgroundQueue
        self.grandOperator = grandOperator
        self.context = grandOperator.coreDataUtil.managedObjectContext
        super.init(name: name)
        self.cache = PersistentEmailCache(persistentImapFolder: self)
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
                                                   context: context) {
            return messages
        } else {
            return []
        }
    }

    override func count() -> UInt {
        let n = Message.countWithName(Message.entityName(), predicate: self.predicateAllMessages(),
                                      context: context)
        return UInt(n)
    }

    override func appendMessage(theMessage: CWMessage) {
        super.appendMessage(theMessage)
    }

    func saveMessage(message: CWMessage) {
        let op = StorePrefetchedMailOperation.init(grandOperator: self.grandOperator,
                                                   accountEmail: connectInfo.email,
                                                   message: message as! CWIMAPMessage)
        backgroundQueue.addOperation(op)
    }
}