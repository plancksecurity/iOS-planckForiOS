//
//  PersistentImapFolder.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

import MessageModel

/**
 A `CWFolder`/`CWIMAPFolder` that is backed by core data. Use on the main thread.
 */
class PersistentImapFolder: CWIMAPFolder, CWCache, CWIMAPCache {
    let comp = "PersistentImapFolder"

    let connectInfo: EmailConnectInfo

    let coreDataUtil: CoreDataUtil
    lazy var privateMOC: NSManagedObjectContext = self.coreDataUtil.privateContext()
    lazy var model: ICdModel = CdModel.init(context: self.privateMOC)

    /** The underlying core data object */
    var folder: CdFolder!

    let backgroundQueue: OperationQueue

    override var nextUID: UInt {
        get {
            var uid: UInt = 0
            privateMOC.performAndWait({
                uid = UInt(self.folder.nextUID.intValue)
            })
            return uid
        }
        set {
            privateMOC.perform({
                self.folder.nextUID = NSNumber(value: newValue)
                self.model.save()
            })
        }
    }

     override var existsCount: UInt {
        get {
            var count: UInt = 0
            privateMOC.performAndWait({
                count = UInt(self.folder.existsCount)
            })
            return count
        }
        set {
            privateMOC.perform({
                self.folder.existsCount = NSNumber(value: newValue)
                self.model.save()
            })
        }
    }

    init(name: String, coreDataUtil: CoreDataUtil, connectInfo: EmailConnectInfo,
         backgroundQueue: OperationQueue) {
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

    func folderObject() -> CdFolder {
        var folder: CdFolder? = nil
        privateMOC.performAndWait({
            if let fo = self.model.insertOrUpdateFolderName(
                self.name(), folderSeparator: nil, accountEmail: self.connectInfo.userId) {
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

    override func setUIDValidity(_ theUIDValidity: UInt) {
        privateMOC.perform() {
            if let uidV = self.folder.uidValidity {
                if uidV.uintValue != theUIDValidity {
                    Log.warnComponent(self.comp,
                        "UIValidity changed, deleting all messages. Folder \(self.folder.name)")
                    self.folder.messages = []
                }
            }
            self.folder.uidValidity = theUIDValidity as NSNumber?
            self.model.save()
        }
    }

    override func uidValidity() -> UInt {
        var i: UInt = 0
        privateMOC.performAndWait({
            if let uidVal = self.folder.uidValidity {
                i = UInt(uidVal.intValue)
            }
        })
        return i
    }

    func predicateAllMessages() -> NSPredicate {
        let p = NSPredicate.init(format: "folder.account.email = %@ and folder.name = %@",
                                 connectInfo.userId,
                                 self.name())
        return p
    }

    override func allMessages() -> [Any] {
        var result = [Any]()
        privateMOC.performAndWait({
            if let messages = self.model.messagesByPredicate(
                self.predicateAllMessages(), sortDescriptors: nil) {
                for m in messages {
                    result.append(m)
                }
            }
        })
        return result
    }

    /**
     This implementation assumes that the index is typically referred to by pantomime
     as the messageNumber.
     */
    override func message(at theIndex: UInt) -> CWMessage? {
        let p = NSPredicate.init(
            format: "folder.account.email = %@ and folder.name = %@ and messageNumber = %d",
            connectInfo.userId, self.name(), theIndex)
        var msg: CdMessage?
        privateMOC.performAndWait({
            msg = self.model.messageByPredicate(p, sortDescriptors: nil)
        })
        return msg?.pantomimeMessageWithFolder(self)
    }

    override func count() -> UInt {
        var count: Int = 0
        privateMOC.performAndWait({
            count = self.model.messageCountByPredicate(self.predicateAllMessages())
        })
        return UInt(count)
    }

    override func lastUID() -> UInt {
        var uid: UInt = 0
        privateMOC.performAndWait({
            uid = self.model.lastUidInFolderNamed(self.name())
        })
        return uid
    }

    func invalidate() {
    }

    func synchronize() -> Bool {
        return true
    }

    func message(withUID theUID: UInt) -> CWIMAPMessage? {
        var result: CWIMAPMessage?
        privateMOC.performAndWait({
            let pUid = NSPredicate.init(format: "uid = %d", theUID)
            let pFolderName = NSPredicate.init(format: "folder.name = %@", self.folder.name)
            let p = NSCompoundPredicate.init(andPredicateWithSubpredicates: [pUid, pFolderName])

            if let msg = self.model.messageByPredicate(p, sortDescriptors: nil) {
                result = msg.pantomimeMessageWithFolder(self)
            } else {
                result = nil
            }
        })
        return result
    }

    /**
     - TODO: This gets called for some weird reason, and it should not. Investigate.
     */
    func removeMessage(withUID theUID: UInt) {
    }

    func write(_ theRecord: CWCacheRecord?, message: CWIMAPMessage) {
        Log.warnComponent(comp, "Writing message \(message)")

        // Quickly store the most important email proporties (synchronously)
        let opQuick = StorePrefetchedMailOperation.init(coreDataUtil: coreDataUtil,
                                                        accountEmail: connectInfo.userId,
                                                        message: message, quick: true)
        opQuick.start()

        // Do all the time-consuming details in the background (asynchronously)
        let op = StorePrefetchedMailOperation.init(coreDataUtil: coreDataUtil,
                                                   accountEmail: connectInfo.userId,
                                                   message: message, quick: false)
        backgroundQueue.addOperation(op)
    }
}
