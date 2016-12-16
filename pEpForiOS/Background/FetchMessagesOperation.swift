//
//  FetchMessagesOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

import MessageModel

/**
 Fetches messages from the server.
 This operation is not intended to be put in a queue (though this should work too).
 It runs asynchronously, but mainly driven by the main runloop through the use of NSStream.
 Therefore it behaves as a concurrent operation, handling the state itself.
 */
open class FetchMessagesOperation: ConcurrentBaseOperation {
    let connectInfo: EmailConnectInfo
    var imapSync: ImapSync!
    var folderToOpen: String
    let connectionManager: ImapConnectionManagerProtocol

    public init(imapSyncData: ImapSyncData, folderName: String = ImapSync.defaultImapInboxName,
                name: String? = nil) {
        self.connectInfo = imapSyncData.connectInfo
        self.connectionManager = imapSyncData
        self.folderToOpen = folderName
        super.init(parentName: name)
    }

    override open func main() {
        if isCancelled {
            markAsFinished()
            return
        }

        imapSync = connectionManager.imapConnection(connectInfo: connectInfo)
        if !checkImapSync(sync: imapSync) {
            markAsFinished()
            return
        }

        let context = Record.Context.default
        context.perform() {
            self.process(context: context)
        }
    }

    func process(context: NSManagedObjectContext) {
        let folderBuilder = ImapFolderBuilder(accountID: self.connectInfo.accountObjectID,
                                              backgroundQueue: self.backgroundQueue,
                                              name: name)

        guard let account = Record.Context.default.object(with: connectInfo.accountObjectID)
            as? CdAccount else {
                addError(Constants.errorCannotFindAccount(component: comp))
                markAsFinished()
                return
        }

        // Treat Inbox specially, as it is the only mailbox
        // that is mandatorily case-insensitive.
        if self.folderToOpen.lowercased() == ImapSync.defaultImapInboxName.lowercased() {
            if let folder = CdFolder.first(with: ["folderType": FolderType.inbox.rawValue,
                                          "account": account]) {
                self.folderToOpen = folder.name!
            }
        }

        self.imapSync.delegate = self
        self.imapSync.folderBuilder = folderBuilder

        if !self.imapSync.openMailBox(name: self.folderToOpen) {
            self.fetchMessages(self.imapSync)
        }
    }

    func fetchMessages(_ sync: ImapSync) {
        do {
            try sync.fetchMessages()
        } catch let err as NSError {
            addError(err)
            waitForFinished()
        }
    }

    open override func cancel() {
        Log.info(component: comp, content: "cancel")
        if let sync = imapSync {
            sync.cancel()
        }
        super.cancel()
    }

    override func markAsFinished() {
        Log.info(component: comp, content: "markAsFinished")
        super.markAsFinished()
    }
}

extension FetchMessagesOperation: ImapSyncDelegate {

    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "authenticationCompleted"))
        markAsFinished()
    }

    public func receivedFolderNames(_ sync: ImapSync, folderNames: [String]?) {
        addError(Constants.errorIllegalState(comp, stateName: "receivedFolderNames"))
        markAsFinished()
    }

    public func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorAuthenticationFailed(comp))
        markAsFinished()
    }

    public func connectionLost(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionLost(comp))
        markAsFinished()
    }

    public func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorConnectionTerminated(comp))
        markAsFinished()
    }

    public func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorTimeout(comp))
        markAsFinished()
    }

    public func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        waitForFinished()
    }

    public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderSyncCompleted"))
        markAsFinished()
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageChanged"))
        markAsFinished()
    }

    public func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        // do nothing
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        fetchMessages(sync)
    }

    public func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderOpenFailed"))
        markAsFinished()
    }

    public func folderStatusCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderStatusCompleted"))
        markAsFinished()
    }

    public func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderListCompleted"))
        markAsFinished()
    }

    public func folderNameParsed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderNameParsed"))
        markAsFinished()
    }

    public func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderAppendCompleted"))
        markAsFinished()
    }

    public func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderAppendFailed"))
        markAsFinished()
    }

    public func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreCompleted"))
        markAsFinished()
    }

    public func messageStoreFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "messageStoreFailed"))
        markAsFinished()
    }

    public func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderCreateCompleted"))
        markAsFinished()
    }

    public func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderCreateFailed"))
        markAsFinished()
    }

    public func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderDeleteCompleted"))
        markAsFinished()
    }

    public func folderDeleteFailed(_ sync: ImapSync, notification: Notification?) {
        addError(Constants.errorIllegalState(comp, stateName: "folderDeleteFailed"))
        markAsFinished()
    }

    public func actionFailed(_ sync: ImapSync, error: NSError) {
        addError(error)
        markAsFinished()
    }
}
