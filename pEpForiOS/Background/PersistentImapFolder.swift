//
//  PersistentImapFolder.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

/**
 A `CWFolder`/`CWIMAPFolder` that is backed by core data.
 */
class PersistentImapFolder: CWIMAPFolder {
    let comp = "PersistentImapFolder"

    let mainContext: NSManagedObjectContext
    let connectInfo: ConnectInfo
    let backgroundQueue: NSOperationQueue
    let grandOperator: IGrandOperator
    let cache: PersistentEmailCache

    override var nextUID: UInt {
        get {
            return super.nextUID
        }
        set {
            super.nextUID = nextUID
            if let folder = folderObject() {
                folder.nextUID = nextUID
                CoreDataUtil.saveContext(managedObjectContext: mainContext)
            } else {
                Log.warn(comp,
                         "Could not set nextUID \(nextUID) for folder (name()) of account \(connectInfo.email)")
            }
        }
    }

    init(name: String, grandOperator: IGrandOperator, connectInfo: ConnectInfo,
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
        var result: [AnyObject] = []
        if let messages = grandOperator.model.messagesByPredicate(self.predicateAllMessages()) {
            for m in messages {
                result.append(m as! AnyObject)
            }
            return result
        } else {
            return []
        }
    }

    /**
     This implementation assumes that the index is typically referred to by pantomime
     as the messageNumber.
     */
    override func messageAtIndex(theIndex: UInt) -> CWMessage? {
        let p = NSPredicate.init(
            format: "folder.account.email = %@ and folder.name = %@ and messageNumber = %d",
            connectInfo.email, self.name(), theIndex)
        let msg = grandOperator.model.messageByPredicate(p)
        return msg?.imapMessage()
    }

    override func count() -> UInt {
        let n = grandOperator.model.messageCountWithPredicate(self.predicateAllMessages())
        return UInt(n)
    }

    override func lastUID() -> UInt {
        let fetch = NSFetchRequest.init(entityName: Message.entityName())
        fetch.fetchLimit = 1
        fetch.sortDescriptors = [NSSortDescriptor.init(key: "uid", ascending: false)]
        do {
            let elems = try mainContext.executeFetchRequest(fetch)
            if elems.count > 0 {
                if elems.count > 1 {
                    Log.warn(comp, "lastUID has found more than one element")
                }
                if let msg = elems[0] as? Message {
                    return UInt(msg.uid!.integerValue)
                } else {
                    Log.warn(comp, "Could not cast core data result to Message")
                }
            } else if elems.count > 0 {
                Log.warn(comp, "lastUID has several objects with the same UID?")
            }
        } catch let error as NSError {
            Log.error(comp, error: error)
        }
        Log.warn(comp, "lastUID no object found, returning 0")
        return 0
    }

    func folderObject() -> Folder? {
        let p = NSPredicate.init(format: "account.email = %@ and name = %@",
                                 connectInfo.email, name())
        if let folder = grandOperator.model.folderByPredicate(p) as? Folder {
            return folder
        } else {
            Log.warn(comp,
                     "Could not fetch folder with name \(name()) of account \(connectInfo.email)")
            return nil
        }
    }

    override func setUIDValidity(theUIDValidity: UInt) {
        if let folder = folderObject() {
            folder.uidValidity = theUIDValidity
            CoreDataUtil.saveContext(managedObjectContext: mainContext)
        } else {
            Log.warn(comp,
                     "Could not set UIDValidity \(theUIDValidity) for folder (name()) of account \(connectInfo.email)")
        }
    }

    override func UIDValidity() -> UInt {
        if let folder = folderObject() {
            if let uidVal = folder.uidValidity {
                return UInt(uidVal.integerValue)
            }
        }
        Log.warn(comp,
                 "Could not get UIDValidity for folder (name()) of account \(connectInfo.email)")
        return 0
    }
}