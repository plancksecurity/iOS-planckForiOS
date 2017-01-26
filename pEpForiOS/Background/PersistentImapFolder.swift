//
//  PersistentImapFolder.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

/**
 A `CWFolder`/`CWIMAPFolder` that is backed by core data. Use on the main thread.
 */
class PersistentImapFolder: CWIMAPFolder, CWCache, CWIMAPCache {
    let comp = "PersistentImapFolder"

    let accountID: NSManagedObjectID

    /** The underlying core data object */
    var folder: CdFolder!

    let backgroundQueue: OperationQueue

    let logName: String?

    var privateMOC: NSManagedObjectContext {
        return Record.Context.background
    }

    override var nextUID: UInt {
        get {
            var uid: UInt = 0
            privateMOC.performAndWait({
                uid = UInt(self.folder.uidNext)
            })
            return uid
        }
        set {
            privateMOC.performAndWait({
                self.folder.uidNext = NSNumber(value: newValue).int64Value
                Record.saveAndWait()
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
            privateMOC.performAndWait({
                self.folder.existsCount = NSNumber(value: newValue).int64Value
                Record.saveAndWait()
            })
        }
    }

    let messageFetchedBlock: MessageFetchedBlock?

    init(name: String, accountID: NSManagedObjectID, backgroundQueue: OperationQueue,
         logName: String? = nil, messageFetchedBlock: MessageFetchedBlock? = nil) {
        self.accountID = accountID
        self.backgroundQueue = backgroundQueue
        self.logName = logName
        self.messageFetchedBlock = messageFetchedBlock
        super.init(name: name)
        self.setCacheManager(self)
        self.folder = folderObject()
    }

    deinit {
        Log.info(component: "PersistentImapFolder: \(logName)", content: "PersistentImapFolder")
    }

    func folderObject() -> CdFolder {
        var folder: CdFolder? = nil
        privateMOC.performAndWait({
            guard let account = self.privateMOC.object(with: self.accountID)
                as? CdAccount else {
                    Log.error(component: self.comp,
                              errorString: "Given objectID is not an account")
                    return
            }
            if let fo = CdFolder.insertOrUpdate(
                folderName: self.name(), folderSeparator: nil, account: account) {
                Record.saveAndWait()
                folder = fo
            }
        })
        return folder!
    }

    override func setUIDValidity(_ theUIDValidity: UInt) {
        privateMOC.performAndWait() {
            if self.folder.uidValidity != Int32(theUIDValidity) {
                Log.warn(
                    component: self.comp,
                    content: "UIValidity changed, deleting all messages. Folder \(self.folder.name)")
                self.folder.messages = []
            }
            self.folder.uidValidity = Int32(theUIDValidity)
            Record.saveAndWait()
        }
    }

    override func uidValidity() -> UInt {
        var i: Int32 = 0
        privateMOC.performAndWait({
            i = self.folder.uidValidity
        })
        return UInt(i)
    }

    override func allMessages() -> [Any] {
        var result = [Any]()
        privateMOC.performAndWait({
            if let messages = CdMessage.all(predicate: self.folder.allMessagesPredicate()) {
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
     Relying on that is dangerous and should be avoided.
     */
    override func message(at theIndex: UInt) -> CWMessage? {
        var msg: CdMessage?
        privateMOC.performAndWait({
            let p = NSPredicate(
                format: "folder = %@ messageNumber = %d", self.folder, theIndex)
            msg = CdMessage.first(predicate: p)
        })
        return msg?.pantomime(folder: self)
    }

    override func count() -> UInt {
        var count: Int = 0
        privateMOC.performAndWait({
            count = self.folder.allMessages().count
        })
        return UInt(count)
    }

    override func firstUID() -> UInt {
        var uid: UInt = 0
        privateMOC.performAndWait({
            uid = self.folder.firstUID()
        })
        return uid
    }

    override func lastUID() -> UInt {
        var uid: UInt = 0
        privateMOC.performAndWait({
            uid = self.folder.lastUID()
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
            let pFolder = NSPredicate.init(format: "parent = %@", self.folder)
            let p = NSCompoundPredicate.init(andPredicateWithSubpredicates: [pUid, pFolder])

            if let msg = CdMessage.first(predicate: p) {
                result = msg.pantomime(folder: self)
            } else {
                result = nil
            }
        })
        return result
    }

    /**
     - TODO: This gets called for some weird reason, and it should not. Investigate.
     */
    func removeMessage(withUID: UInt) {
    }

    public func write(_ theRecord: CWCacheRecord?, message: CWIMAPMessage,
                      messageUpdate: CWMessageUpdate) {
        Log.warn(component: comp, content: "Writing message \(message), \(messageUpdate)")

        let opQuick = StorePrefetchedMailOperation(
            accountID: accountID, message: message, messageUpdate: messageUpdate, name: logName,
            messageFetchedBlock: messageFetchedBlock)
        opQuick.start()
    }
}
