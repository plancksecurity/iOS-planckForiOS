//
//  FetchNumberOfNewMailsOperation.swift
//  pEp
//
//  Created by Andreas Buff on 18.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData
import MessageModel

/// Fetches UIDs of  new (to us) messages in a given folder and returns its count.
class FetchNumberOfNewMailsOperation: ImapSyncOperation {
    typealias CompletionBlock = (_ numNewMails: Int?) -> ()

    private var folderToOpen = ImapSync.defaultImapInboxName
    private var syncDelegate: FetchNumberOfNewMailsSyncDelegate?
    private var numNewMailsFetchedBlock: CompletionBlock?

    init(parentName: String = #function,
         errorContainer: ServiceErrorProtocol = ErrorContainer(),
         imapSyncData: ImapSyncData,
         folderName: String = ImapSync.defaultImapInboxName,
         numNewMailsFetchedBlock: CompletionBlock? = nil) {
        self.folderToOpen = folderName
        self.numNewMailsFetchedBlock = numNewMailsFetchedBlock
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

    // MARK: - Operation

    override public func main() {
        if !shouldRun() {
            return
        }

        if !checkImapSync() {
            return
        }

        let context = Record.Context.background
        context.perform() {
            self.process(context: context)
        }
    }

    public override func cancel() {
        Log.info(component: comp, content: "cancel")
        if let sync = imapSyncData.sync {
            sync.cancel()
        }
        super.cancel()
    }

    // MARK: - ImapSyncOperation

    public override func waitForBackgroundTasksToFinish() {
        syncDelegate = nil
        super.waitForBackgroundTasksToFinish()
    }

    // MARK: - Internal

    private func process(context: NSManagedObjectContext) {
        let folderBuilder = ImapFolderBuilder(
            accountID: self.imapSyncData.connectInfo.accountObjectID,
            backgroundQueue: self.backgroundQueue, name: name)
        guard let account = Record.Context.background.object(
            with: imapSyncData.connectInfo.accountObjectID)
            as? CdAccount else {
                addError(Constants.errorCannotFindAccount(component: comp))
                waitForBackgroundTasksToFinish()
                return
        }
        // Treat Inbox specially, as it is the only mailbox
        // that is mandatorily case-insensitive.
        if self.folderToOpen.lowercased() == ImapSync.defaultImapInboxName.lowercased() {
            if let folder = CdFolder.first(attributes: ["folderTypeRawValue": FolderType.inbox.rawValue,
                                                        "account": account]) {
                self.folderToOpen = folder.name!
            }
        }
        syncDelegate = FetchNumberOfNewMailsSyncDelegate(errorHandler: self)
        self.imapSyncData.sync?.delegate = syncDelegate
        self.imapSyncData.sync?.folderBuilder = folderBuilder

        if let sync = imapSyncData.sync {
            if !sync.openMailBox(name: self.folderToOpen) {
                self.fetchUids(sync)
            }
        }
    }

    fileprivate func fetchUids(_ sync: ImapSync) {
        do {
            try sync.fetchUidsForNewMessages()
        } catch let err as NSError {
            addIMAPError(err)
            waitForBackgroundTasksToFinish()
        }
    }
    
    fileprivate func handleResult(uids: [Int]?) {
        numNewMailsFetchedBlock?(uids?.count)
        waitForBackgroundTasksToFinish()
    }
}

class FetchNumberOfNewMailsSyncDelegate: DefaultImapSyncDelegate {
    public override func folderFetchCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? FetchNumberOfNewMailsOperation)?.handleResult(uids:
            notification?.userInfo?["Uids"] as? [Int]
        )
    }

    public override func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? FetchNumberOfNewMailsOperation)?.fetchUids(sync)
    }
}
