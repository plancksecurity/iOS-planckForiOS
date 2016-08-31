//
//  SyncFlagsToServerOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 31/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

public class SyncFlagsToServerOperation: ConcurrentBaseOperation {
    let comp = "SyncFlagsToServerOperation"

    let connectionManager: ConnectionManager
    let coreDataUtil: ICoreDataUtil

    var targetFolderName: String!

    let connectInfo: ConnectInfo

    var imapSync: ImapSync!

    lazy var privateMOC: NSManagedObjectContext = self.coreDataUtil.privateContext()
    lazy var model: IModel = Model.init(context: self.privateMOC)

    public var numberOfMessagesSynced = 0

    public init(folder: IFolder,
                connectionManager: ConnectionManager, coreDataUtil: ICoreDataUtil) {
        self.connectInfo = folder.account.connectInfo
        self.targetFolderName = folder.name
        self.connectionManager = connectionManager
        self.coreDataUtil = coreDataUtil
    }

    public override func main() {
        self.imapSync = self.connectionManager.emailSyncConnection(self.connectInfo)
        self.imapSync.delegate = self
        self.imapSync.start()
    }

    func syncNextMessage() {
        privateMOC.performBlock() {
            let pFlagsChanged = NSPredicate.init(format: "flags != flagsFromServer")
            let pFolder = NSPredicate.init(format: "folder.name = %@",
                self.targetFolderName)
            let p = NSCompoundPredicate.init(
                andPredicateWithSubpredicates: [pFlagsChanged, pFolder])
            let messages = self.model.messagesByPredicate(
                p, sortDescriptors: [NSSortDescriptor.init(
                    key: "receivedDate", ascending: true)])
            guard let m = messages?.first else {
                self.markAsFinished()
                return
            }
            self.updateFlagsForMessage(m)
        }
    }

    func updateFlagsForMessage(message: IMessage) {

    }
}

extension SyncFlagsToServerOperation: ImapSyncDelegate {
    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        if !self.cancelled {
            syncNextMessage()
        }
    }

    public func authenticationFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorAuthenticationFailed(comp))
        markAsFinished()
    }

    public func connectionLost(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorConnectionLost(comp))
        markAsFinished()
    }

    public func connectionTerminated(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorConnectionTerminated(comp))
        markAsFinished()
    }

    public func connectionTimedOut(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorConnectionTimeout(comp))
        markAsFinished()
    }

    public func folderPrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderPrefetchCompleted"))
        markAsFinished()
    }

    public func messageChanged(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageChanged"))
        markAsFinished()
    }

    public func messagePrefetchCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messagePrefetchCompleted"))
    }

    public func folderOpenCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenCompleted"))
        markAsFinished()
    }

    public func folderOpenFailed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenFailed"))
        markAsFinished()
    }

    public func folderStatusCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderStatusCompleted"))
        markAsFinished()
    }

    public func folderListCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderListCompleted"))
        markAsFinished()
    }

    public func folderNameParsed(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderNameParsed"))
        markAsFinished()
    }

    public func folderAppendCompleted(sync: ImapSync, notification: NSNotification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderAppendCompleted"))
        markAsFinished()
    }

    public func actionFailed(sync: ImapSync, error: NSError) {
        addError(error)
        markAsFinished()
    }
}