//
//  PrefetchEmailsOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

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

    init(grandOperator: GrandOperator, connectInfo: ConnectInfo) {
        self.grandOperator = grandOperator
        self.connectInfo = connectInfo

        queue = dispatch_queue_create("PrefetchEmailsOperation helper", DISPATCH_QUEUE_SERIAL)
    }

    override func main() {
        Log.info(comp, "main")
        if self.cancelled {
            return
        }
        imapSync = grandOperator.connectionManager.emaiSyncConnection(connectInfo)
        imapSync.delegate = self
        imapSync.start()
    }

    func updateFolderNames(folderNames: [String]) {
        let context = grandOperator.coreDataUtil.confinedManagedObjectContext()
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
