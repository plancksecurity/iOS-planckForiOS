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

    /** The underlying core data object. Only use from the internal context. */
    var folder: CdFolder

    let backgroundQueue: OperationQueue

    let logName: String?

    let privateMOC: NSManagedObjectContext

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

    init?(name: String, accountID: NSManagedObjectID, backgroundQueue: OperationQueue,
          logName: String? = nil, messageFetchedBlock: MessageFetchedBlock? = nil) {
        self.accountID = accountID
        self.backgroundQueue = backgroundQueue
        self.logName = logName
        self.messageFetchedBlock = messageFetchedBlock
        let context = Record.Context.background
        self.privateMOC = context

        if let f = PersistentImapFolder.folderObject(
            context: context, name: name, accountID: accountID) {
            self.folder = f
        } else {
            return nil
        }

        super.init(name: name)

        self.setCacheManager(self)
    }

    deinit {
        let logID = logName ?? "<unknown>"
        Log.info(component: #function, content: logID)
    }

    static func folderObject(context: NSManagedObjectContext,
                             name: String,
                             accountID: NSManagedObjectID) -> CdFolder? {
        var folder: CdFolder? = nil
        context.performAndWait() {
            guard let account = context.object(with: accountID)
                as? CdAccount else {
                    Log.error(component: #function,
                              errorString: "Given objectID is not an account")
                    return
            }
            if let (fo, _) = CdFolder.insertOrUpdate(
                folderName: name, folderSeparator: nil, account: account) {
                Record.saveAndWait()
                folder = fo
            }
        }
        return folder
    }

    override func setUIDValidity(_ theUIDValidity: UInt) {
        privateMOC.performAndWait() {
            if self.folder.uidValidity != Int32(theUIDValidity) {
                Log.warn(
                    component: self.comp,
                    content: "UIValidity changed, deleting all messages. Folder \(String(describing: self.folder.name))")
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
            if let messages = CdMessage.all(
                predicate: self.folder.allMessagesIncludingDeletedPredicate()) {
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
                format: "parent = %@ and messageNumber = %d", self.folder, theIndex)
            msg = CdMessage.first(predicate: p)
        })
        return msg?.pantomimeQuick(folder: self)
    }

    override func count() -> UInt {
        var count: Int = 0
        privateMOC.performAndWait({
            count = self.folder.allMessages().count
        })
        return UInt(count)
    }

    override func lastMSN() -> UInt {
        var msn: UInt = 0
        privateMOC.performAndWait() {
            let lastUID = self.folder.lastUID()
            if let cwMsg = self.message(withUID: lastUID, context: self.privateMOC) {
                msn = cwMsg.messageNumber()
            }
        }
        return msn
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

    func message(withUID theUID: UInt, context: NSManagedObjectContext) -> CWIMAPMessage? {
        let pUid = NSPredicate.init(format: "uid = %d", theUID)
        let pFolder = NSPredicate.init(format: "parent = %@", self.folder)
        let p = NSCompoundPredicate.init(andPredicateWithSubpredicates: [pUid, pFolder])

        if let msg = CdMessage.first(predicate: p), let cwFolder = folder.cwFolder() {
            return msg.pantomimeQuick(folder: cwFolder)
        } else {
            return nil
        }
    }

    func message(withUID theUID: UInt) -> CWIMAPMessage? {
        var result: CWIMAPMessage?
        privateMOC.performAndWait {
            result = self.message(withUID: theUID, context: self.privateMOC)
        }
        return result
    }

    func removeMessage(withUID: UInt) {
    }

    public func write(_ theRecord: CWCacheRecord?, message: CWIMAPMessage,
                      messageUpdate: CWMessageUpdate) {
        let opStore = StorePrefetchedMailOperation(
            accountID: accountID, message: message, messageUpdate: messageUpdate, name: logName,
            messageFetchedBlock: messageFetchedBlock)
        let opID = unsafeBitCast(opStore, to: UnsafeRawPointer.self)
        Log.warn(component: comp, content: "Writing message \(message), \(messageUpdate) for \(opID)")
        backgroundQueue.addOperation(opStore)


        // While it would be desirable to store messages asynchronously,
        // it's not the correct semantics pantomime, and therefore the layers above, expect.
        // It might correctly work in-app, but can mess up the unit tests since they might signal
        // "finish" before all messages have been stored.
        opStore.waitUntilFinished()

        Log.warn(component: comp, content: "Wrote message \(message) for \(opID)")
    }
}
