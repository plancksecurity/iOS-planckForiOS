//
//  FetchNumberOfNewMailsOperation.swift
//  pEp
//
//  Created by Andreas Buff on 18.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData
import MessageModel

/// Figures out the number new (to us) messages for a given folder.
class FetchNumberOfNewMailsOperation: ImapSyncOperation {
    public typealias CompletionBlock = (_ numNewMails: Int?) -> ()

    var folderToOpen = ImapSync.defaultImapInboxName
    var syncDelegate: FetchNumberOfNewMailsSyncDelegate?
    var numNewMailsFetchedBlock: CompletionBlock?

    public init(
        parentName: String = #function, errorContainer: ServiceErrorProtocol = ErrorContainer(),
        imapSyncData: ImapSyncData,
        folderName: String = ImapSync.defaultImapInboxName,
        numNewMailsFetchedBlock: CompletionBlock? = nil) {
        self.folderToOpen = folderName
        self.numNewMailsFetchedBlock = numNewMailsFetchedBlock
        super.init(parentName: parentName, errorContainer: errorContainer,
                   imapSyncData: imapSyncData)
    }

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

    func process(context: NSManagedObjectContext) {
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

    func fetchUids(_ sync: ImapSync) {
        do {
            try sync.fetchUidsForNewMessages()
        } catch let err as NSError {
            addIMAPError(err)
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

    //BUFF:
    fileprivate func handleResult(uids: [Int]?) {
        numNewMailsFetchedBlock?(uids?.count)

        waitForBackgroundTasksToFinish()
    }
    //FFUB
}

class FetchNumberOfNewMailsSyncDelegate: DefaultImapSyncDelegate {
    public override func folderFetchCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? FetchNumberOfNewMailsOperation)?.handleResult(uids:
            notification?.userInfo?["Uids"] as? [Int]
        )
    }

//    public override func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
//
//        //BUFF: handle uids
//         (errorHandler as? FetchNumberOfNewMailsOperation)?.handleResult(numMails: 666)
//    }

    public override func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
        (errorHandler as? FetchNumberOfNewMailsOperation)?.fetchUids(sync)
    }
}
