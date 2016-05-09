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
 A `CWFolder`/`CWIMAPFolder` that is backed by core data. Use on the main thread.
 */
class PersistentImapFolder: CWIMAPFolder {
    let comp = "PersistentImapFolder"

    let mainContext: NSManagedObjectContext
    let connectInfo: ConnectInfo
    let backgroundQueue: NSOperationQueue
    let grandOperator: IGrandOperator
    let cache: PersistentEmailCache

    /** The underlying core data object */
    var folder: IFolder!

    override var nextUID: UInt {
        get {
            return UInt(folder.nextUID.integerValue)
        }
        set {
            folder.nextUID = newValue
            CoreDataUtil.saveContext(managedObjectContext: mainContext)
        }
    }

     override var existsCount: UInt {
        get {
            return UInt(folder.existsCount)
        }
        set {
            folder.existsCount = newValue
            CoreDataUtil.saveContext(managedObjectContext: mainContext)
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
        self.folder = folderObject()
    }

    func folderObject() -> IFolder {
        if let folder = grandOperator.model.insertOrUpdateFolderName(
            name(), folderType: Account.AccountType.Imap, accountEmail: connectInfo.email) {
            return folder
        } else {
            abort()
        }
    }

    override func setUIDValidity(theUIDValidity: UInt) {
        if folder.uidValidity != theUIDValidity {
            Log.warn(comp,
                     "UIValidity changed, deleting all messages. Folder \(folder.name)")
            folder.messages = []
        }
        folder.uidValidity = theUIDValidity
        CoreDataUtil.saveContext(managedObjectContext: mainContext)
    }

    override func UIDValidity() -> UInt {
        if let uidVal = folder.uidValidity {
            return UInt(uidVal.integerValue)
        }
        return 0
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
     - Todo: This must be synchronized with the fetching. The way it currently is
     implemented is not feasible, since the messageIDs would have to be recomputed.
     */
    override func messageAtIndex(theIndex: UInt) -> CWMessage? {
        let p = NSPredicate.init(
            format: "folder.account.email = %@ and folder.name = %@ and messageNumber = %d",
            connectInfo.email, self.name(), theIndex)
        let msg = grandOperator.model.messageByPredicate(p)
        return msg?.imapMessage()
    }

    override func count() -> UInt {
        let n = grandOperator.model.messageCountByPredicate(self.predicateAllMessages())
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
}