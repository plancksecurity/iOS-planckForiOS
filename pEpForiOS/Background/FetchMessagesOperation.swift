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
 Calling this block indicates that a message has been fetched and stored.
 */
public typealias MessageFetchedBlock = (_ message: CdMessage) -> ()

/**
 Fetches new messages from the server.
 This operation is not intended to be put in a queue (though this should work too).
 It runs asynchronously, but mainly driven by the main runloop through the use of NSStream.
 Therefore it behaves as a concurrent operation, handling the state itself.
 */
public class FetchMessagesOperation: ImapSyncOperation {
    var folderToOpen: String
    let messageFetchedBlock: MessageFetchedBlock?
    var syncDelegate: FetchMessagesSyncDelegate?

    init(
        parentName: String = #function, errorContainer: ServiceErrorProtocol = ErrorContainer(),
        imapSyncData: ImapSyncData,
        folderName: String = ImapSync.defaultImapInboxName,
        messageFetchedBlock: MessageFetchedBlock? = nil) {
        self.folderToOpen = folderName
        self.messageFetchedBlock = messageFetchedBlock
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    override public func main() {
        if !checkImapSync() {
            markAsFinished()
            return
        }
        let context = privateMOC
        privateMOC.perform() {
            self.process(context: context)
        }
    }

    func process(context: NSManagedObjectContext) {
        let folderBuilder = ImapFolderBuilder(
            accountID: self.imapSyncData.connectInfo.accountObjectID,
            backgroundQueue: self.backgroundQueue, name: name,
            messageFetchedBlock: messageFetchedBlock)

        guard let account = context.object(
            with: imapSyncData.connectInfo.accountObjectID)
            as? CdAccount else {
                addError(BackgroundError.CoreDataError.couldNotFindAccount(info: comp))
                waitForBackgroundTasksToFinish()
                return
        }

        // Treat Inbox specially, as it is the only mailbox
        // that is mandatorily case-insensitive.
        if self.folderToOpen.lowercased() == ImapSync.defaultImapInboxName.lowercased() {
            if let folder = CdFolder.first(attributes: ["folderTypeRawValue": FolderType.inbox.rawValue,
                                                        "account": account]) {
                folderToOpen = folder.name!
            }
        }

        syncDelegate = FetchMessagesSyncDelegate(errorHandler: self)
        self.imapSyncData.sync?.delegate = syncDelegate
        self.imapSyncData.sync?.folderBuilder = folderBuilder

        if let sync = imapSyncData.sync {
            if !sync.openMailBox(name: self.folderToOpen) {
                fetchMessages(sync)
            }
        }
    }

    func fetchMessages(_ sync: ImapSync) {
        do {
            try sync.fetchMessages()
        } catch {
            addIMAPError(error)
            waitForBackgroundTasksToFinish()
        }
    }

    public override func cancel() {
        Log.info(component: comp, content: "cancel")
        if let sync = imapSyncData.sync {
            sync.cancel()
        }
        super.cancel()
    }

    public override func waitForBackgroundTasksToFinish() {
        syncDelegate = nil
        super.waitForBackgroundTasksToFinish()
    }
}

class FetchMessagesSyncDelegate: DefaultImapSyncDelegate {
    public override func folderFetchCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? FetchMessagesOperation)?.waitForBackgroundTasksToFinish()
    }

    public override func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
        // do nothing
    }

    public override func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? FetchMessagesOperation)?.fetchMessages(sync)
    }
}
