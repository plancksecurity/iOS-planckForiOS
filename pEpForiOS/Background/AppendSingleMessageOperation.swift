//
//  AppendSingleMessageOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26/08/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

public class AppendSingleMessageOperation: ConcurrentBaseOperation {
    let comp = "AppendSingleMessageOperation"

    let messageID: NSManagedObjectID
    let targetFolderID: NSManagedObjectID
    let connectInfo: ConnectInfo

    let connectionManager: ConnectionManager
    let coreDataUtil: ICoreDataUtil

    lazy var privateMOC: NSManagedObjectContext = self.coreDataUtil.privateContext()
    lazy var model: IModel = Model.init(context: self.privateMOC)

    var imapSync: ImapSync!

    var cwMessageToAppend: CWIMAPMessage!
    var targetFolderName: String!

    public init(message: IMessage, account: IAccount, targetFolder: IFolder,
                connectionManager: ConnectionManager, coreDataUtil: ICoreDataUtil) {
        self.messageID = (message as! Message).objectID
        self.connectInfo = account.connectInfo
        self.targetFolderID = (targetFolder as! Folder).objectID
        self.connectionManager = connectionManager
        self.coreDataUtil = coreDataUtil
    }

    override public func main() {
        privateMOC.performBlock({
            guard let message = self.privateMOC.objectWithID(self.messageID) as?
                IMessage
                else {
                    return
            }
            guard let targetFolder = self.privateMOC.objectWithID(self.targetFolderID) as?
                IFolder
                else {
                    return
            }

            self.targetFolderName = targetFolder.name
            self.cwMessageToAppend = PEPUtil.pantomimeMailFromMessage(message)

            self.imapSync = self.connectionManager.emailSyncConnection(self.connectInfo)
            self.imapSync.delegate = self
            self.imapSync.start()
        })
    }
}

extension AppendSingleMessageOperation: ImapSyncDelegate {
    public func authenticationCompleted(sync: ImapSync, notification: NSNotification?) {
        if !self.cancelled {
            let folder = CWIMAPFolder.init(name: targetFolderName)
            folder.setStore(sync.imapStore)
            guard let rawData = cwMessageToAppend.dataValue() else {
                markAsFinished()
                return
            }
            folder.appendMessageFromRawSource(rawData, flags: nil, internalDate: nil)
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
        markAsFinished()
    }

    public func actionFailed(sync: ImapSync, error: NSError) {
        addError(error)
        markAsFinished()
    }
}