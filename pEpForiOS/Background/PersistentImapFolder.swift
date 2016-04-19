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
    let backgroundQueue: NSOperationQueue
    let grandOperator: GrandOperator

    init(name: String, grandOperator: GrandOperator, connectInfo: ConnectInfo,
         backgroundQueue: NSOperationQueue) {
        self.connectInfo = connectInfo
        self.backgroundQueue = backgroundQueue
        self.grandOperator = grandOperator
        self.context = grandOperator.coreDataUtil.managedObjectContext
        super.init(name: name)
    }

    /**
     - Note: This must always be called from the main thread. As called by Pantomime, this should
     be the case.
     */
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

    override func appendMessage(theMessage: CWMessage) {
        let op = StorePrefetchedMailOperation.init(grandOperator: self.grandOperator,
                                                   accountEmail: connectInfo.email,
                                                   message: theMessage as! CWIMAPMessage)
        //backgroundQueue.addOperation(op)
    }
}