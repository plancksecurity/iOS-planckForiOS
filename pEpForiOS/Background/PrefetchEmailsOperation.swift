//
//  PrefetchEmailsOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

class PrefetchEmailsOperation: NSOperation {
    let comp = "PrefetchEmailsOperation"

    let grandOperator: GrandOperator
    let connectInfo: ConnectInfo
    var imapSync: ImapSync!

    /**
     This is needed, although stuff already happens in the background,
     because `CWTCPConnection` uses `NSStream` and they get scheduled on the main thread.
     This could be rewritten but you'd still need an additional runloop thread.
     */
    let queue: dispatch_queue_t

    /**
     - Note: This context is confined to `queue`.
     */
    var context: NSManagedObjectContext!

    let folderToOpen: String

    init(grandOperator: GrandOperator, connectInfo: ConnectInfo, folder: String?) {
        self.grandOperator = grandOperator
        self.connectInfo = connectInfo
        if let folder = folder {
            folderToOpen = folder
        } else {
            folderToOpen = ImapSync.defaultImapInboxName
        }

        queue = dispatch_queue_create("PrefetchEmailsOperation helper", DISPATCH_QUEUE_SERIAL)
        super.init()
        background {
            self.context = grandOperator.coreDataUtil.confinedManagedObjectContext()
        }
    }

    override func main() {
        Log.info(comp, "main")
        if self.cancelled {
            return
        }
        imapSync = grandOperator.connectionManager.emaiSyncConnection(connectInfo)
        imapSync.delegate = self
        imapSync.cache = self
        imapSync.start()
    }

    func updateFolderNames(folderNames: [String]) {
        for folderName in folderNames {
            Account.insertOrUpdateFolderWithName(folderName, folderType: Account.AccountType.Imap,
                                                 accountEmail: self.connectInfo.email,
                                                 context: context)
        }
       CoreDataUtil.saveContext(managedObjectContext: context)
    }

    func background(block: () -> Void) {
        dispatch_async(queue, block)
    }

}

extension PrefetchEmailsOperation: ImapSyncDelegate {

    func authenticationCompleted(notification: NSNotification) {
        if !self.cancelled {
            imapSync.waitForFolders()
        }
    }

    func receivedFolderNames(folderNames: [String]) {
        if !self.cancelled {
            background {
                self.updateFolderNames(folderNames)
            }
            imapSync.openMailBox(folderToOpen)
        }
    }

    func authenticationFailed(notification: NSNotification) {
    }

    func connectionLost(notification: NSNotification) {
    }

    func connectionTerminated(notification: NSNotification) {
    }

    func connectionTimedOut(notification: NSNotification) {
    }

    func folderPrefetchCompleted(notification: NSNotification) {
        // TODO: op is finished
    }

    func messageChanged(notification: NSNotification) {
    }

    func messagePrefetchCompleted(notification: NSNotification) {
    }

    func folderOpenCompleted(notification: NSNotification!) {
    }

    func folderOpenFailed(notification: NSNotification!) {
    }
}

extension PrefetchEmailsOperation: EmailCache {
    func invalidate() {
    }

    func synchronize() -> Bool {
        return true
    }

    func count() -> UInt {
        return 0
    }

    func removeMessageWithUID(theUID: UInt) {
    }

    func UIDValidity() -> UInt {
        return 0
    }

    func setUIDValidity(theUIDValidity: UInt) {
    }

    func messageWithUID(theUID: UInt) -> CWIMAPMessage! {
        return nil
    }

    func dumpMessage(msg: CWMessage) {
        print("CWMessage: contentType(\(msg.contentType()))",
              " isInitialized(\(msg.isInitialized()))\n",
              " content(\(msg.content()))")
    }

    func writeRecord(theRecord: CWCacheRecord!, message: CWIMAPMessage!) {
        // TODO: Test for mails that are obviously pEp and should never
        // be displayed, like beacon messages.
        let folder = message.folder()
        print("write UID(\(message.UID())) folder(\(folder.name()))")
        dumpMessage(message)
    }
}