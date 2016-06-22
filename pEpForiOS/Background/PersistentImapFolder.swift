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
    let grandOperator: IGrandOperator

    /** The underlying core data object */
    var folder: IFolder!

    let backgroundQueue: NSOperationQueue

    override var nextUID: UInt {
        get {
            return UInt(folder.nextUID.integerValue)
        }
        set {
            folder.nextUID = newValue
            grandOperator.operationModel().save()
        }
    }

     override var existsCount: UInt {
        get {
            return UInt(folder.existsCount)
        }
        set {
            folder.existsCount = newValue
            grandOperator.operationModel().save()
        }
    }

    init(name: String, grandOperator: IGrandOperator, connectInfo: ConnectInfo,
         backgroundQueue: NSOperationQueue) {
        self.connectInfo = connectInfo
        self.grandOperator = grandOperator
        self.backgroundQueue = backgroundQueue
        super.init(name: name)
        self.setCacheManager(self)
        self.folder = folderObject()
    }

    deinit {
        print("PersistentImapFolder")
    }

    func folderObject() -> IFolder {
        if let folder = grandOperator.operationModel().insertOrUpdateFolderName(
            name(), accountEmail: connectInfo.email) {
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
        grandOperator.operationModel().save()
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

    override func allMessages() -> [AnyObject] {
        var result: [AnyObject] = []
        if let messages = grandOperator.operationModel().messagesByPredicate(
            self.predicateAllMessages(), sortDescriptors: nil) {
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
        let msg = grandOperator.operationModel().messageByPredicate(p, sortDescriptors: nil)
        return msg?.imapMessageWithFolder(self)
    }

    override func count() -> UInt {
        let n = grandOperator.operationModel().messageCountByPredicate(self.predicateAllMessages())
        return UInt(n)
    }

    override func lastUID() -> UInt {
        return grandOperator.operationModel().lastUidInFolderNamed(name())
    }

    func invalidate() {
    }

    func synchronize() -> Bool {
        return true
    }

    func messageWithUID(theUID: UInt) -> CWIMAPMessage? {
        var result: CWIMAPMessage?
        let p = NSPredicate.init(format: "uid = %d", theUID)
        let privateMOC = grandOperator.coreDataUtil.privateContext()
        privateMOC.performBlockAndWait({
            let model = Model.init(context: privateMOC)
            if let msg = model.messageByPredicate(p, sortDescriptors: nil) {
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
        let opQuick = StorePrefetchedMailOperation.init(coreDataUtil: grandOperator.coreDataUtil,
                                                        accountEmail: connectInfo.email,
                                                        message: message, quick: true)
        opQuick.start()

        // Do all the time-consuming details in the background (asynchronously)
        let op = StorePrefetchedMailOperation.init(coreDataUtil: grandOperator.coreDataUtil,
                                                   accountEmail: connectInfo.email,
                                                   message: message, quick: false)
        backgroundQueue.addOperation(op)
    }
}