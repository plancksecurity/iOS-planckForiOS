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
    let cache: PersistentEmailCache = PersistentEmailCache()

    /**
     - Note: What is typically fetched in IMAP is:
     From To Cc Subject Date Message-ID References In-Reply-To
     */
    let pathsToWatch = ["from", "to", "recipients", "messageID", "receivedDate", "subject"]

    init(name: String, grandOperator: GrandOperator, connectInfo: ConnectInfo,
         backgroundQueue: NSOperationQueue) {
        self.connectInfo = connectInfo
        self.backgroundQueue = backgroundQueue
        self.grandOperator = grandOperator
        self.context = grandOperator.coreDataUtil.managedObjectContext
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
        addAsObserver(theMessage)
    }

    func addAsObserver(message: CWMessage) {
        watchedMessages.addObject(message)
        for path in pathsToWatch {
            message.addObserver(self, forKeyPath: path,
                                options: .New,
                                context: nil)
        }
    }

    func removeAsObserver(message: CWMessage) {
        watchedMessages.removeObject(message)
        for path in pathsToWatch {
            message.removeObserver(self, forKeyPath: path)
        }
    }

    func saveMessage(message: CWMessage) {
        let op = StorePrefetchedMailOperation.init(grandOperator: self.grandOperator,
                                                   accountEmail: connectInfo.email,
                                                   message: message as! CWIMAPMessage)
        backgroundQueue.addOperation(op)
    }

    func canPersistMail(message: CWMessage) -> Bool {
        if message.recipients().count > 0 && message.from() != nil
            && message.subject() != nil && message.receivedDate() != nil {
            return true
        }
        return false
    }

    // MARK: -- KVO

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?,
                                         change: [String : AnyObject]?,
                                         context: UnsafeMutablePointer<Void>) {
        if keyPath != nil && pathsToWatch.contains(keyPath!) {
            if let message = object as? CWMessage {
                Log.info(comp, "message (\(message)) changed \(keyPath!): \(change![NSKeyValueChangeNewKey])")
                if canPersistMail(message) {
                    saveMessage(message)
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change,
                                         context: context)
        }
    }
}