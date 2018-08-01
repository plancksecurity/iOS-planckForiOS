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
class PersistentImapFolder: CWIMAPFolder {
    let accountID: NSManagedObjectID
    let folderID: NSManagedObjectID

    /** The underlying core data object. Only use from the internal context. */
    var folder: CdFolder

    let backgroundQueue: OperationQueue

    let logName: String

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
                self.privateMOC.saveAndLogErrors()
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
                self.privateMOC.saveAndLogErrors()
            })
        }
    }

    let messageFetchedBlock: MessageFetchedBlock?

    init?(name: String, accountID: NSManagedObjectID, backgroundQueue: OperationQueue,
          logName: String? = #function, messageFetchedBlock: MessageFetchedBlock? = nil) {
        self.accountID = accountID
        self.backgroundQueue = backgroundQueue
        self.logName = "PersistentImapFolder (\(logName ?? "<unknown>"))"
        self.messageFetchedBlock = messageFetchedBlock
        let context = Record.Context.background
        self.privateMOC = context

        if let f = PersistentImapFolder.folderObject(
            context: context, logName: logName, name: name, accountID: accountID) {
            self.folder = f
            self.folderID = f.objectID
        } else {
            return nil
        }
        super.init(name: name)
        self.setCacheManager(self)
    }

    func functionName(_ name: String) -> String {
        return PersistentImapFolder.functionName(logName: logName, functionName: name)
    }

    static func functionName(logName: String? = #function, functionName: String) -> String {
        if let ln = logName {
            return "\(ln): \(functionName)"
        } else {
            return functionName
        }
    }

    static func folderObject(context: NSManagedObjectContext,
                             logName: String? = #function,
                             name: String,
                             accountID: NSManagedObjectID) -> CdFolder? {
        var folder: CdFolder? = nil
        context.performAndWait() {
            guard let account = context.object(with: accountID)
                as? CdAccount else {
                    Log.error(component: functionName(logName: logName, functionName: #function),
                              errorString: "Given objectID is not an account")
                    return
            }
            if let (fo, _) = CdFolder.insertOrUpdate(
                folderName: name, folderSeparator: nil, folderType: nil, account: account) {
                context.saveAndLogErrors()
                folder = fo
            }
        }
        return folder
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
        var result: CWMessage?
        privateMOC.performAndWait({
            let p = NSPredicate(
                format: "parent = %@ and imap.messageNumber = %d", self.folder, theIndex)
            let msg = CdMessage.first(predicate: p)
            result = msg?.pantomimeQuick(folder: self)
        })
        return result
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
            if let cwMsg = self.cwMessage(withUID: lastUID, context: self.privateMOC) {
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

    func cdMessage(withUID theUID: UInt, context: NSManagedObjectContext) -> CdMessage? {
        let pUid = NSPredicate.init(format: "uid = %d", theUID)
        let pFolder = NSPredicate.init(format: "parent = %@", self.folder)
        let p = NSCompoundPredicate.init(andPredicateWithSubpredicates: [pUid, pFolder])

        return CdMessage.first(predicate: p)
    }

    func cwMessage(withUID theUID: UInt, context: NSManagedObjectContext) -> CWIMAPMessage? {
        if let cdMsg = cdMessage(withUID: theUID, context: context),
            let cwFolder = folder.cwFolder() {
            return cdMsg.pantomimeQuick(folder: cwFolder)
        } else {
            return nil
        }
    }

    override func remove(_ cwMessage: CWMessage) {
        if let cwImapMessage = cwMessage as? CWIMAPMessage {
            let uid = cwImapMessage.uid()
            removeMessage(withUID: uid)
        } else {
            Log.shared.warn(component: functionName(#function),
                            content: "Should remove/expunge message that is not a CWIMAPMessage")
        }
    }

    override func matchUID(_ uid: UInt, withMSN msn: UInt) {
        super.matchUID(uid, withMSN: msn)
        Log.shared.info(component: functionName(#function),
                        content: "\(msn): \(uid)")
        let opMatch = MatchUidToMsnOperation(
            parentName: functionName(#function),
            folderID: folderID, uid: uid, msn: msn)
        backgroundQueue.addOperation(opMatch)
        // We might have feched a message soley to update its MSN, we rely on it, so we have to wait
        opMatch.waitUntilFinished()
    }
}

//MARK: - CWCache
extension PersistentImapFolder: CWCache {
    func invalidate() {
        Log.shared.errorAndCrash(component: #function, errorString: "Unimplemented stub")
        // if intentionally, please mark so
    }

    func synchronize() -> Bool {
        return true
    }
}

//MARK: - CWIMAPCache
extension PersistentImapFolder: CWIMAPCache {
    func message(withUID theUID: UInt) -> CWIMAPMessage? {
        var result: CWIMAPMessage?
        privateMOC.performAndWait {
            result = self.cwMessage(withUID: theUID, context: self.privateMOC)
        }
        return result
    }

    func removeMessage(withUID: UInt) {
        privateMOC.performAndWait {
            if let cdMsg = self.cdMessage(withUID: withUID, context: self.privateMOC) {
                let cdFolder = cdMsg.parent
                let msn = cdMsg.imap?.messageNumber
                cdMsg.deleteAndInformDelegate(context: self.privateMOC)
                if let theCdFolder = cdFolder, let theMsn = msn {
                    let p1 = NSPredicate(format: "parent = %@ and imap.messageNumber > %d",
                                         theCdFolder, theMsn)
                    let cdMsgs = CdMessage.all(predicate: p1,
                                               in: self.privateMOC) as? [CdMessage] ?? []
                    for aCdMsg in cdMsgs {
                        let oldMsn = aCdMsg.imapFields().messageNumber
                        if oldMsn > 0 {
                            aCdMsg.imapFields().messageNumber = oldMsn - 1
                        }
                    }
                    Record.saveAndWait(context: privateMOC)
                }
            } else {
                Log.shared.warn(component: self.functionName(#function),
                                content: "Could not find message by UID for expunging.")
            }
        }
    }

    override func uidValidity() -> UInt {
        var i: Int32 = 0
        privateMOC.performAndWait({
            i = self.folder.uidValidity
        })
        return UInt(i)
    }

    override func setUIDValidity(_ theUIDValidity: UInt) {
        guard let context = self.folder.managedObjectContext else {
            Log.shared.errorAndCrash(component: #function, errorString: "Dangling folder")
            return
        }
        context.performAndWait() {
            if self.folder.uidValidity != Int32(theUIDValidity) {
                Log.warn(component: self.functionName(#function),
                         content: "UIValidity changed, deleting all messages. " +
                    "Folder \(String(describing: self.folder.name))")
                // For some reason messages are not deleted when removing it from folder
                // (even cascade is the delete rule). This causes crashes saving the context,
                // as it holds invalid messages that have no parent folder.
                // That is why we are deleting the messages manually.
                if let messages =  self.folder.messages?.allObjects as? [CdMessage] {
                    for cdMessage in messages  {
                        cdMessage.deleteAndInformDelegate(context: context)
                    }
                }
                self.folder.uidValidity = Int32(theUIDValidity)
                context.saveAndLogErrors()
            }
        }
    }

    public func write(_ theRecord: CWCacheRecord?, message: CWIMAPMessage,
                      messageUpdate: CWMessageUpdate) {
        let opStore = StorePrefetchedMailOperation(
            parentName: functionName(#function),
            accountID: accountID, message: message, messageUpdate: messageUpdate,
            messageFetchedBlock: messageFetchedBlock)
        let opID = unsafeBitCast(opStore, to: UnsafeRawPointer.self)
        Log.warn(component: functionName(#function),
                 content: "Writing message \(message), \(messageUpdate) for \(opID)")
        backgroundQueue.addOperation(opStore)

        // While it would be desirable to store messages asynchronously,
        // it's not the correct semantics pantomime, and therefore the layers above, expect.
        // It might correctly work in-app, but can mess up the unit tests since they might signal
        // "finish" before all messages have been stored.
        opStore.waitUntilFinished()

        Log.info(component: functionName(#function),
                 content: "Wrote message \(message) for \(opID)")
    }
}
