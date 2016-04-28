//
//  PrefetchEmailsOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import CoreData

public class ImapFolderBuilder: NSObject, CWFolderBuilding {
    let connectInfo: ConnectInfo
    let backgroundQueue: NSOperationQueue
    let grandOperator: IGrandOperator

    public init(grandOperator: IGrandOperator, connectInfo: ConnectInfo,
         backgroundQueue: NSOperationQueue) {
        self.connectInfo = connectInfo
        self.grandOperator = grandOperator
        self.backgroundQueue = backgroundQueue
    }

    public func folderWithName(name: String!) -> CWFolder! {
        return PersistentImapFolder(name: name, grandOperator: grandOperator,
                                    connectInfo: connectInfo, backgroundQueue: backgroundQueue)
            as CWFolder
    }
}

/**
 This operation is not intended to be put in a queue (though this should work too).
 It runs asynchronously, but mainly driven by the main runloop through the use of NSStream.
 Therefore it behaves as a concurrent operation, handling the state itself.
 */
class PrefetchEmailsOperation: BaseOperation {
    let comp = "PrefetchEmailsOperation"

    let connectInfo: ConnectInfo
    let backgroundQueue: NSOperationQueue
    var imapSync: ImapSync!
    let folderBuilder: ImapFolderBuilder

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

    init(grandOperator: IGrandOperator, connectInfo: ConnectInfo, folder: String?) {
        self.connectInfo = connectInfo
        if let folder = folder {
            folderToOpen = folder
        } else {
            folderToOpen = ImapSync.defaultImapInboxName
        }

        backgroundQueue = NSOperationQueue.init()
        folderBuilder = ImapFolderBuilder.init(grandOperator: grandOperator,
                                               connectInfo: connectInfo,
                                               backgroundQueue: backgroundQueue)

        super.init(grandOperator: grandOperator)
    }

    override func main() {
        Log.info(comp, "main")
        if self.cancelled {
            return
        }
        imapSync = grandOperator.connectionManager.emaiSyncConnection(connectInfo)
        imapSync.delegate = self
        imapSync.folderBuilder = folderBuilder
        imapSync.start()
    }

    func updateFolderNames(folderNames: [String]) {
        let op = StoreFoldersOperation.init(grandOperator: self.grandOperator,
                                            folders: folderNames, email: self.connectInfo.email)
        backgroundQueue.addOperation(op)
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

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?,
                                         change: [String : AnyObject]?,
                                         context: UnsafeMutablePointer<Void>) {
        if keyPath == "operationCount" {
            if let newValue = change?[NSKeyValueChangeNewKey] {
                if newValue.intValue == 0 {
                    markAsFinished()
                }
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change,
                                         context: context)
        }
    }

}

extension PrefetchEmailsOperation: ImapSyncDelegate {

    func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        if !self.cancelled {
            imapSync.waitForFolders()
        }
    }

    func receivedFolderNames(sync: ImapSync, folderNames: [String]) {
        if !self.cancelled {
            self.updateFolderNames(folderNames)
            imapSync.openMailBox(folderToOpen, prefetchMails: true)
        }
    }

    func authenticationFailed(sync: ImapSync, notification: NSNotification?) {
    }

    func connectionLost(sync: ImapSync, notification: NSNotification?) {
    }

    func connectionTerminated(sync: ImapSync, notification: NSNotification?) {
    }

    func connectionTimedOut(sync: ImapSync, notification: NSNotification?) {
    }

    func folderPrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        waitForFinished()
    }

    func messageChanged(sync: ImapSync, notification: NSNotification?) {
    }

    func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
    }

    func folderOpenCompleted(sync: ImapSync, notification: NSNotification?) {
    }

    func folderOpenFailed(sync: ImapSync, notification: NSNotification?) {
    }
}