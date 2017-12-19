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

    private let context = Record.Context.background
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

        context.perform() { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash(component: #function, errorString: "I lost me")
                return
            }
            me.process()
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

    private func cdFolder() -> CdFolder? {
        var result: CdFolder?
        context.performAndWait {
            guard let account = context.object(
                with: imapSyncData.connectInfo.accountObjectID)
                as? CdAccount else {
                    addError(Constants.errorCannotFindAccount(component: comp))
                    waitForBackgroundTasksToFinish()
                    return
            }
            // Treat Inbox specially, as it is the only mailbox that is mandatorily case-insensitive.
            // Thus we search for
            if self.folderToOpen.lowercased() == ImapSync.defaultImapInboxName.lowercased() {
                if let folder = CdFolder.first(attributes:
                    ["folderTypeRawValue": FolderType.inbox.rawValue,   "account": account]) {
                    result = folder
                    return
                }
            }
            result = CdFolder.first(attributes: ["name": folderToOpen, "account": account])
        }
        return result
    }

    private func process() {
        let folderBuilder = ImapFolderBuilder(
            accountID: self.imapSyncData.connectInfo.accountObjectID,
            backgroundQueue: self.backgroundQueue, name: name)

        let cdFolderToOpen = cdFolder()
        if  let name = cdFolderToOpen?.name {
            folderToOpen = name
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
        let uids = validateResult(uids: uids)
        numNewMailsFetchedBlock?(uids?.count)
        waitForBackgroundTasksToFinish()
    }

    /// If no new mails exist, the server returns the UID of the last (also locally) existing mail.
    /// This method handles this case and filters the existing UID.
    ///
    /// - Parameter uids: uids to validate
    /// - Returns:  empty array if uids contains only one, locally existing UID,
    ///             the unmodified uids otherwize
    private func validateResult(uids: [Int]?) ->[Int]? {
        if let safeUids = uids, safeUids.count != 1 {
            // We have to validate only if uids.count == 1
            return uids
        }
        guard let cdFolderToOpen = cdFolder() else {
            Log.shared.errorAndCrash(component: #function, errorString: "No folder")
            return nil
        }
        guard let theOneAndOnlyUid = uids?.first else {
            Log.shared.errorAndCrash(component: #function,
                                     errorString:
                "We should have exactly one UID at this point, but have nothing.")
            return nil
        }
        let messageForUidPredicate = NSPredicate(format: "parent=%@ AND uid=%d", cdFolderToOpen,
                                                 theOneAndOnlyUid)
        if let _ = CdMessage.all(predicate: messageForUidPredicate) {
            // A message with the given UID exists, thus the server response means
            // that "there are no new messages"
            return []
        }

        return uids
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
