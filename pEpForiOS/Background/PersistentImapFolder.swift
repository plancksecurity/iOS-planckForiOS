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
class PersistentImapFolder: CWIMAPFolder, CWCache, CWIMAPCache {
    let comp = "PersistentImapFolder"

    let connectInfo: ConnectInfo

    let coreDataUtil: ICoreDataUtil
    lazy var privateMOC: NSManagedObjectContext = self.coreDataUtil.privateContext()
    lazy var model: IModel = Model.init(context: self.privateMOC)

    /** The underlying core data object */
    var folder: IFolder!

    let backgroundQueue: NSOperationQueue

    override var nextUID: UInt {
        get {
            var uid: UInt = 0
            privateMOC.performBlockAndWait({
                uid = UInt(self.folder.nextUID.integerValue)
            })
            return uid
        }
        set {
            privateMOC.performBlock({
                self.folder.nextUID = newValue
                self.model.save()
            })
        }
    }

     override var existsCount: UInt {
        get {
            var count: UInt = 0
            privateMOC.performBlockAndWait({
                count = UInt(self.folder.existsCount)
            })
            return count
        }
        set {
            privateMOC.performBlock({
                self.folder.existsCount = newValue
                self.model.save()
            })
        }
    }

    init(name: String, coreDataUtil: ICoreDataUtil, connectInfo: ConnectInfo,
         backgroundQueue: NSOperationQueue) {
        self.coreDataUtil = coreDataUtil
        self.connectInfo = connectInfo
        self.backgroundQueue = backgroundQueue
        super.init(name: name)
        self.setCacheManager(self)
        self.folder = folderObject()
    }

    deinit {
        print("PersistentImapFolder")
    }

    func folderObject() -> IFolder {
        var folder: IFolder? = nil
        privateMOC.performBlockAndWait({
            if let fo = self.model.insertOrUpdateFolderName(
                self.name(), folderSeparator: nil, accountEmail: self.connectInfo.email) {
                self.model.save()
                folder = fo
            }
        })
        if let f = folder {
            return f
        } else {
            abort()
        }
    }

    override func setUIDValidity(theUIDValidity: UInt) {
        privateMOC.performBlock({
            if self.folder.uidValidity != theUIDValidity {
                Log.warnComponent(self.comp,
                    "UIValidity changed, deleting all messages. Folder \(self.folder.name)")
                self.folder.messages = []
            }
            self.folder.uidValidity = theUIDValidity
            self.model.save()
        })
    }

    override func UIDValidity() -> UInt {
        var i: UInt = 0
        privateMOC.performBlockAndWait({
            if let uidVal = self.folder.uidValidity {
                i = UInt(uidVal.integerValue)
            }
        })
        return i
    }

    func predicateAllMessages() -> NSPredicate {
        let p = NSPredicate.init(format: "folder.account.email = %@ and folder.name = %@",
                                 connectInfo.email,
                                 self.name())
        return p
    }

    override func allMessages() -> [AnyObject] {
        var result: [AnyObject] = []
        privateMOC.performBlockAndWait({
            if let messages = self.model.messagesByPredicate(
                self.predicateAllMessages(), sortDescriptors: nil) {
                for m in messages {
                    result.append(m as AnyObject)
                }
            }
        })
        return result
    }

    /**
     This implementation assumes that the index is typically referred to by pantomime
     as the messageNumber.
     */
    override func messageAtIndex(theIndex: UInt) -> CWMessage? {
        let p = NSPredicate.init(
            format: "folder.account.email = %@ and folder.name = %@ and messageNumber = %d",
            connectInfo.email, self.name(), theIndex)
        var msg: IMessage?
        privateMOC.performBlockAndWait({
            msg = self.model.messageByPredicate(p, sortDescriptors: nil)
        })
        return msg?.imapMessageWithFolder(self)
    }

    override func count() -> UInt {
        var count: Int = 0
        privateMOC.performBlockAndWait({
            count = self.model.messageCountByPredicate(self.predicateAllMessages())
        })
        return UInt(count)
    }

    override func lastUID() -> UInt {
        var uid: UInt = 0
        privateMOC.performBlockAndWait({
            uid = self.model.lastUidInFolderNamed(self.name())
        })
        return uid
    }

    func invalidate() {
    }

    func synchronize() -> Bool {
        return true
    }

    func messageWithUID(theUID: UInt) -> CWIMAPMessage? {
        var result: CWIMAPMessage?
        privateMOC.performBlockAndWait({
            let pUid = NSPredicate.init(format: "uid = %d", theUID)
            let pFolderName = NSPredicate.init(format: "folder.name = %@", self.folder.name)
            let p = NSCompoundPredicate.init(andPredicateWithSubpredicates: [pUid, pFolderName])

            if let msg = self.model.messageByPredicate(p, sortDescriptors: nil) {
                result = msg.imapMessageWithFolder(self)
            } else {
                result = nil
            }
        })
        return result
    }

    /**
     - TODO: This gets called for some weird reason, and it should not. Investigate.
     */
    func removeMessageWithUID(theUID: UInt) {
    }

    func writeRecord(theRecord: CWCacheRecord?, message: CWIMAPMessage) {
        // Quickly store the most important email proporties (synchronously)
        let opQuick = StorePrefetchedMailOperation.init(coreDataUtil: coreDataUtil,
                                                        accountEmail: connectInfo.email,
                                                        message: message, quick: true)
        opQuick.start()

        // Do all the time-consuming details in the background (asynchronously)
        let op = StorePrefetchedMailOperation.init(coreDataUtil: coreDataUtil,
                                                   accountEmail: connectInfo.email,
                                                   message: message, quick: false)
        backgroundQueue.addOperation(op)
    }
}