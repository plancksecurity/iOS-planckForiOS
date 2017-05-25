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
open class FetchMessagesOperation: ImapSyncOperation {
    var folderToOpen: String
    let messageFetchedBlock: MessageFetchedBlock?

    public init(
        parentName: String? = nil, errorContainer: ServiceErrorProtocol = ErrorContainer(),
        imapSyncData: ImapSyncData,
        folderName: String = ImapSync.defaultImapInboxName,
        messageFetchedBlock: MessageFetchedBlock? = nil) {
        self.folderToOpen = folderName
        self.messageFetchedBlock = messageFetchedBlock
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    override open func main() {
        if !shouldRun() {
            return
        }

        if !checkImapSync() {
            return
        }

        let context = Record.Context.default
        context.perform() {
            self.process(context: context)
        }
    }

    func process(context: NSManagedObjectContext) {
        let folderBuilder = ImapFolderBuilder(
            accountID: self.imapSyncData.connectInfo.accountObjectID,
            backgroundQueue: self.backgroundQueue, name: name,
            messageFetchedBlock: messageFetchedBlock)

        guard let account = Record.Context.default.object(
            with: imapSyncData.connectInfo.accountObjectID)
            as? CdAccount else {
                addError(Constants.errorCannotFindAccount(component: comp))
                markAsFinished()
                return
        }

        // Treat Inbox specially, as it is the only mailbox
        // that is mandatorily case-insensitive.
        if self.folderToOpen.lowercased() == ImapSync.defaultImapInboxName.lowercased() {
            if let folder = CdFolder.first(attributes: ["folderType": FolderType.inbox.rawValue,
                                          "account": account]) {
                self.folderToOpen = folder.name!
            }
        }

        self.imapSyncData.sync?.delegate = self
        self.imapSyncData.sync?.folderBuilder = folderBuilder

        if let sync = imapSyncData.sync {
            if !sync.openMailBox(name: self.folderToOpen) {
                self.fetchMessages(sync)
            }
        }
    }

    func fetchMessages(_ sync: ImapSync) {
        do {
            try sync.fetchMessages()
        } catch let err as NSError {
            addIMAPError(err)
            waitForFinished()
        }
    }

    open override func cancel() {
        Log.info(component: comp, content: "cancel")
        if let sync = imapSyncData.sync {
            sync.cancel()
        }
        super.cancel()
    }
}

extension FetchMessagesOperation: ImapSyncDelegate {

    public func authenticationCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "authenticationCompleted"))
        markAsFinished()
    }

    public func receivedFolderNames(_ sync: ImapSync, folderNames: [String]?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "receivedFolderNames"))
        markAsFinished()
    }

    public func authenticationFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorAuthenticationFailed(comp))
        markAsFinished()
    }

    public func connectionLost(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorConnectionLost(comp))
        markAsFinished()
    }

    public func connectionTerminated(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorConnectionTerminated(comp))
        markAsFinished()
    }

    public func connectionTimedOut(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorTimeout(comp))
        markAsFinished()
    }

    public func folderPrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        waitForFinished()
    }

    public func folderSyncCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderSyncCompleted"))
        markAsFinished()
    }

    public func folderSyncFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderSyncFailed"))
        markAsFinished()
    }

    public func messageChanged(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "messageChanged"))
        markAsFinished()
    }

    public func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        // do nothing
    }

    public func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        fetchMessages(sync)
    }

    public func folderOpenFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderOpenFailed"))
        markAsFinished()
    }

    public func folderStatusCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderStatusCompleted"))
        markAsFinished()
    }

    public func folderListCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderListCompleted"))
        markAsFinished()
    }

    public func folderNameParsed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderNameParsed"))
        markAsFinished()
    }

    public func folderAppendCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderAppendCompleted"))
        markAsFinished()
    }

    public func folderAppendFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderAppendFailed"))
        markAsFinished()
    }

    public func messageStoreCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "messageStoreCompleted"))
        markAsFinished()
    }

    public func messageStoreFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "messageStoreFailed"))
        markAsFinished()
    }

    public func folderCreateCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderCreateCompleted"))
        markAsFinished()
    }

    public func folderCreateFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderCreateFailed"))
        markAsFinished()
    }

    public func folderDeleteCompleted(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderDeleteCompleted"))
        markAsFinished()
    }

    public func folderDeleteFailed(_ sync: ImapSync, notification: Notification?) {
        addIMAPError(Constants.errorIllegalState(comp, stateName: "folderDeleteFailed"))
        markAsFinished()
    }

    public func badResponse(_ sync: ImapSync, response: String?) {
        addIMAPError(ImapSyncError.badResponse(response))
        markAsFinished()
    }
}
