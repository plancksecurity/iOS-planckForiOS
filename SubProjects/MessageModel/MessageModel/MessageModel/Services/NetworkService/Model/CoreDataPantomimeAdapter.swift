//
//  CwImapFolderToCdFolderMapper.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

#if EXT_SHARE
import pEpIOSToolboxForExtensions
#else
import pEpIOSToolbox
#endif

import PantomimeFramework

/// This class bridges calls from Pantomime CWIMAPFolder to our persistant layer.
/// All public methods are called from pantomime.
/// This class allows Pantomime get messages, count them, remove them, or persist them, among other operations.
class CoreDataPantomimeAdapter: CWIMAPFolder {
    private let accountID: NSManagedObjectID

    /** The underlying core data object. Only use from the internal context. */
    private var cdFolder: CdFolder
    private var cdAccount: CdAccount {
        return cdFolder.account!
    }

    private let privateMOC: NSManagedObjectContext

    override var nextUID: UInt {
        get {
            var uid: UInt = 0
            privateMOC.performAndWait { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                uid = UInt(me.cdFolder.uidNext)
            }
            return uid
        }
        set {
            privateMOC.performAndWait { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                let newValueInt64 = Int64(newValue)
                if me.cdFolder.uidNext != newValueInt64 {
                    me.cdFolder.uidNext = newValueInt64
                    me.privateMOC.saveAndLogErrors()
                }
            }
        }
    }

    override var existsCount: UInt {
        get {
            var count: UInt = 0
            privateMOC.performAndWait { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                count = UInt(me.cdFolder.existsCount)
            }
            return count
        }
        set {
            privateMOC.performAndWait { [weak self] in
                guard let me = self else {
                    Log.shared.errorAndCrash("Lost myself")
                    return
                }
                let newValueInt64 = Int64(newValue)
                if me.cdFolder.existsCount != newValueInt64 {
                    me.cdFolder.existsCount = newValueInt64
                    me.privateMOC.saveAndLogErrors()
                }
            }
        }
    }

    init?(name: String, accountID: NSManagedObjectID) {
        self.accountID = accountID
        privateMOC = Stack.shared.newPrivateConcurrentContext

        if let f = CoreDataPantomimeAdapter.setupCdFolder(name: name,
                                                      parentAccountID: accountID,
                                                      context: privateMOC) {
            cdFolder = f
        } else {
            return nil
        }
        super.init(name: name)
        setCacheManager(self)
    }

    // This is static to be able to use it in init without using `self` before calling super.init
    static private func setupCdFolder(name: String,
                                      parentAccountID: NSManagedObjectID,
                                      context: NSManagedObjectContext) -> CdFolder? {
        var createe: CdFolder? = nil
        context.performAndWait {
            guard let account = context.cdAccount(from: parentAccountID) else {
                Log.shared.error(
                    "Given objectID is not an account: %@",
                    parentAccountID.description)
                return
            }
            if let cdFOlder = CdFolder.updateOrCreate(folderName: name,
                                                     folderSeparator: nil,
                                                     folderType: nil,
                                                     account: account,
                                                     context: context) {
                context.saveAndLogErrors()
                createe = cdFOlder
            }
        }
        return createe
    }

    override func allMessages() -> [Any] {
        var result = [Any]()
        privateMOC.performAndWait {
            let p = CdMessage.PredicateFactory.allMessagesIncludingDeleted(parentFolder: cdFolder)
            result = CdMessage.all(predicate: p,
                                   in: privateMOC) ?? []
        }
        return result
    }

    /**
     This implementation assumes that the index is typically referred to by pantomime
     as the messageNumber.
     Relying on that is dangerous and should be avoided.
     */
    override func message(at theIndex: UInt) -> CWMessage? {
        var result: CWMessage?
        privateMOC.performAndWait{ [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let isNotFake = CdMessage.PredicateFactory.isNotFakeMessage()
            let msgAtIdx = NSPredicate(format: "parent = %@ and imap.messageNumber = %d",
                                       me.cdFolder,
                                       theIndex)
            let p = NSCompoundPredicate(andPredicateWithSubpredicates: [isNotFake, msgAtIdx])
            let msg = CdMessage.first(predicate: p, in: me.privateMOC)
            result = msg?.pantomimeQuick(folder: me)
        }
        return result
    }

    override func count() -> UInt {
        var count: Int = 0
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            count = me.cdFolder.allMessages(context: me.privateMOC).count
        }
        return UInt(count)
    }

    override func lastMSN() -> UInt {
        var msn: UInt = 0
        privateMOC.performAndWait() { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let lastUID = me.cdFolder.lastUID(context: me.privateMOC)
            if let cwMsg = me.cwMessage(withUID: lastUID) {
                msn = cwMsg.messageNumber()
            }
        }
        return msn
    }

    override func firstUID() -> UInt {
        var uid: UInt = 0
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            uid = me.cdFolder.firstUID(context: me.privateMOC)
        }
        return uid
    }

    override func lastUID() -> UInt {
        var uid: UInt = 0
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            uid = me.cdFolder.lastUID(context: me.privateMOC)
        }
        return uid
    }

    private func cdMessage(withUID uid: UInt) -> CdMessage? {
        let p = CdMessage.PredicateFactory.parentFolder(cdFolder, uid: uid)

        return CdMessage.first(predicate: p, in: privateMOC)
    }

    private func cwMessage(withUID theUID: UInt) -> CWIMAPMessage? {
        guard
            let cdMsg = cdMessage(withUID: theUID),
            let cwFolder = cdFolder.cwFolder()
            else {
                return nil
        }
        return cdMsg.pantomimeQuick(folder: cwFolder)
    }

    override func remove(_ cwMessage: CWMessage) {
        guard let cwImapMessage = cwMessage as? CWIMAPMessage else {
            Log.shared.warn("Should remove/expunge message that is not a CWIMAPMessage")
            return
        }
        let uid = cwImapMessage.uid()
        removeMessage(withUID: uid)
    }

    override func matchUID(_ uid: UInt, withMSN msn: UInt) {
        super.matchUID(uid, withMSN: msn)
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            CdFolder.matchUidToMsn(folderID: me.cdFolder.objectID,
                                   uid: uid,
                                   msn: msn,
                                   context: me.privateMOC)
        }
    }
}

//MARK: - CWCache

// Dummy implementations.
extension CoreDataPantomimeAdapter: CWCache {
    func invalidate() {
        // do nothing.
    }

    func synchronize() -> Bool {
        return true
    }
}

//MARK: - CWIMAPCache

extension CoreDataPantomimeAdapter: CWIMAPCache {

    func message(withUID theUID: UInt) -> CWIMAPMessage? {
        var result: CWIMAPMessage?
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            result = me.cwMessage(withUID: theUID)
        }
        return result
    }

    func removeMessage(withUID: UInt) {
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            guard let cdMsg = me.cdMessage(withUID: withUID) else {
                Log.shared.info("Could not find message by UID for expunging.")
                return
            }
            let cdFolder = cdMsg.parent
            let msn = cdMsg.imap?.messageNumber
            cdMsg.delete(context: me.privateMOC)
            me.privateMOC.saveAndLogErrors()

            guard let theCdFolder = cdFolder, let theMsn = msn else {
                Log.shared.errorAndCrash("I _think_ this is not a valid case. It was failing silently before implementing the guard though. If you figure this is a valid case, lower the log to not crash and leave a comment describing why this is a valid case.")
                return
            }
            let p1 = NSPredicate(format: "%K = %@ and %K > %d",
                                 CdMessage.RelationshipName.parent, theCdFolder,
                                 RelationshipKeyPath.cdMessage_imap_messageNum, theMsn)
            let cdMsgs = CdMessage.all(predicate: p1, in: me.privateMOC) as? [CdMessage] ?? []
            for aCdMsg in cdMsgs {
                let oldMsn = aCdMsg.imapFields(context: me.privateMOC).messageNumber
                if oldMsn > 0 {
                    aCdMsg.imapFields(context: me.privateMOC).messageNumber = oldMsn - 1
                }
            }
            me.privateMOC.saveAndLogErrors()
        }
    }

    override func uidValidity() -> UInt {
        var i: Int32 = 0
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            i = me.cdFolder.uidValidity
        }
        return UInt(i)
    }

    override func setUIDValidity(_ theUIDValidity: UInt) {
        privateMOC.performAndWait() { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            let uidValidityNeverFetchedFromServer = me.cdFolder.uidValidity == 0
            if !uidValidityNeverFetchedFromServer && me.cdFolder.uidValidity != Int32(theUIDValidity) {
                Log.shared.warn(
                    "UIValidity changed, deleting all messages. %@",
                    String(describing: me.cdFolder.name))
                // For some reason messages are not deleted when removing it from folder
                // (even cascade is the delete rule). This causes crashes saving the context,
                // as it holds invalid messages that have no parent folder.
                // That is why we are deleting the messages manually.
                if let messages =  me.cdFolder.messages?.allObjects as? [CdMessage] {
                    for cdMessage in messages  {
                        cdMessage.delete(context: privateMOC)
                    }
                    privateMOC.saveAndLogErrors()
                }
            }

            if me.cdFolder.uidValidity != Int32(theUIDValidity) {
                me.cdFolder.uidValidity = Int32(theUIDValidity)
                privateMOC.saveAndLogErrors()
            }
        }
    }

    func write(_ theRecord: CWCacheRecord?,
               message: CWIMAPMessage,
               messageUpdate: CWMessageUpdate) {
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }

            guard let cdAccount =  me.privateMOC.object(with: me.accountID) as? CdAccount else {
                    Log.shared.errorAndCrash("Need an existing account")
                    return
            }
            CdMessage.insertOrUpdate(pantomimeMessage: message,
                                     account: cdAccount,
                                     messageUpdate: messageUpdate,
                                     context: me.privateMOC)
        }
    }
}
