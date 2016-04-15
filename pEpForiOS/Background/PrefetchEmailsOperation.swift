//
//  PrefetchEmailsOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

/**
 This operation is no intended to be put in a queue, It runs asynchronously, but mainly
 driven by the main runloop through the use of NSStream. Therefore it behaves as a
 concurrent operation, handling the state itself.
 */
class PrefetchEmailsOperation: NSOperation {
    let comp = "PrefetchEmailsOperation"

    let grandOperator: GrandOperator
    let connectInfo: ConnectInfo
    let backgroundQueue: NSOperationQueue
    var imapSync: ImapSync!
    var myFinished: Bool = false

    override var executing: Bool {
        return !finished
    }

    override var asynchronous: Bool {
        return true
    }

    override var finished: Bool {
        return myFinished && backgroundQueue.operationCount == 0
    }

    let folderToOpen: String

    init(grandOperator: GrandOperator, connectInfo: ConnectInfo, folder: String?) {
        self.grandOperator = grandOperator
        self.connectInfo = connectInfo
        if let folder = folder {
            folderToOpen = folder
        } else {
            folderToOpen = ImapSync.defaultImapInboxName
        }

        backgroundQueue = NSOperationQueue.init()

        super.init()
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
        let op = StoreFoldersOperation.init(grandOperator: self.grandOperator,
                                            folders: folderNames, email: self.connectInfo.email)
        backgroundQueue.addOperation(op)
    }

    func savePrefetchedMessage(msg: CWIMAPMessage) {
        let folder = msg.folder()
    }

    override static func automaticallyNotifiesObserversForKey(keyPath: String) -> Bool {
        var automatic: Bool = false
        if keyPath == "isFinished" {
            automatic = false
        } else {
            automatic = super.automaticallyNotifiesObserversForKey(keyPath)
        }
        return automatic
    }

    func waitForFinished() {
        if backgroundQueue.operationCount == 0 {
            markAsFinished()
        } else {
            backgroundQueue.addObserver(self, forKeyPath: "operationCount",
                                        options: .New,
                                        context: nil)
        }
    }

    func markAsFinished() {
        willChangeValueForKey("isFinished")
        myFinished = true
        didChangeValueForKey("isFinished")
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?,
                                         change: [String : AnyObject]?,
                                         context: UnsafeMutablePointer<Void>) {
        if keyPath == "operationCount" {
            markAsFinished()
        }
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
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
            self.updateFolderNames(folderNames)
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
        waitForFinished()
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

    /**
     In general, a prefetch will yield these header fields:
     ```From To Cc Subject Date Message-ID References In-Reply-To```
     */
    func writeRecord(theRecord: CWCacheRecord!, message: CWIMAPMessage!) {
        //print("write UID(\(message.UID())) folder(\(folder.name()))")
        //dumpMessage(message)
        self.savePrefetchedMessage(message)
    }
}