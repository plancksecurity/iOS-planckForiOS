//
//  FetchNumberOfNewMailsOperation.swift
//  pEp
//
//  Created by Andreas Buff on 18.12.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData

import pEpIOSToolbox

/// Fetches UIDs of  new (to us) messages in a given folder and returns its count.
class FetchNumberOfNewMailsOperation: ImapSyncOperation {
    typealias CompletionBlock = (_ numNewMails: Int?) -> ()

    private var folderToOpen = ImapConnection.defaultInboxName
    private var numNewMailsFetchedBlock: CompletionBlock?

    init(parentName: String = #function,
         context: NSManagedObjectContext? = nil,
         errorContainer: ErrorContainerProtocol = ErrorPropagator(),
         imapConnection: ImapConnectionProtocol,
         folderName: String = ImapConnection.defaultInboxName,
         numNewMailsFetchedBlock: CompletionBlock? = nil) {
        self.folderToOpen = folderName
        self.numNewMailsFetchedBlock = numNewMailsFetchedBlock
        super.init(parentName: parentName,
                   context: context,
                   errorContainer: errorContainer,
                   imapConnection: imapConnection)
    }

    // MARK: - Operation

    override public func main() {
        if !checkImapSync() {
            waitForBackgroundTasksAndFinish()
            return
        }

        process()
    }

    override public func cancel() {
        imapConnection.cancel()
        super.cancel()
    }
}

// MARK: - Private

extension FetchNumberOfNewMailsOperation {

    private func cdFolder() -> CdFolder? {
        guard
            let account = imapConnection.cdAccount(moc: privateMOC) else {
                addError(BackgroundError.CoreDataError.couldNotFindAccount(info: comp))
                waitForBackgroundTasksAndFinish()
                return nil
        }
        // Treat Inbox specially, as it is the only mailbox that is mandatorily case-insensitive.
        // Thus we search for
        if folderToOpen.isInboxFolderName() {
            if let folder = CdFolder.first(attributes:
                ["folderTypeRawValue": FolderType.inbox.rawValue,   "account": account], in: privateMOC) {
                return folder
            }
        }
        return CdFolder.first(attributes: ["name": folderToOpen, "account": account],
                              in: privateMOC)
    }

    private func process() {
        privateMOC.performAndWait () { [weak self] in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }

            let cdFolderToOpen = me.cdFolder()
            if let name = cdFolderToOpen?.name {
                me.folderToOpen = name
            }

            me.syncDelegate = FetchNumberOfNewMailsSyncDelegate(errorHandler: me)
            me.imapConnection.delegate = me.syncDelegate
        }

        if !imapConnection.openMailBox(name: folderToOpen, updateExistsCount: false) {
            fetchUids(imapConnection)
        }
    }

    /// If no new mails exist, the server returns the UID of the last (also locally) existing mail.
    /// This method handles this case and filters the existing UID.
    ///
    /// - Parameter uids: uids to validate
    /// - Returns:  empty array if uids contains only one, locally existing UID,
    ///             the unmodified uids otherwize
    private func validateResult(uids: [Int]?) ->[Int]? {
        var result: [Int]? = nil
        privateMOC.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            if let safeUids = uids, safeUids.count != 1 {
                // We have to validate only if uids.count == 1
                result = uids
            }
            guard let cdFolderToOpen = me.cdFolder() else {
                Log.shared.errorAndCrash("No folder")
                return
            }
            guard let theOneAndOnlyUid = uids?.first else {
                // There are zero mails on server.
                return
            }
            let messageForUidPredicate = NSPredicate(format: "%K = %@ AND %K = %d",
                                                     CdMessage.RelationshipName.parent, cdFolderToOpen,
                                                     CdMessage.AttributeName.uid, theOneAndOnlyUid)
            if let _ = CdMessage.all(predicate: messageForUidPredicate, in: me.privateMOC) {
                // A message with the given UID exists, thus the server response means
                // that "there are no new messages". In other words, the server returns the last
                // UID on server in case no new messages exist on server.
                result = []
            } else {
                result = uids
            }
        }

        return result
    }

    private func fetchUids(_ imapConnection: ImapConnectionProtocol) {
        // MUST NOT be called from withing a perform block or backgroundQueue operation
        do {
            try imapConnection.fetchUidsForNewMessages()
        } catch {
            handle(error: error)
        }
    }
}

// MARK: - Callback Handler

extension FetchNumberOfNewMailsOperation {

    fileprivate func handleResult(uids: [Int]?) {
        let uids = validateResult(uids: uids)
        numNewMailsFetchedBlock?(uids?.count)
        waitForBackgroundTasksAndFinish()
    }
    
    fileprivate func handleFolderOpenCompleted(imapConnection: ImapConnectionProtocol) {
        fetchUids(imapConnection)
    }
}

// MARK: - ImapSyncDelegate

class FetchNumberOfNewMailsSyncDelegate: DefaultImapConnectionDelegate {
    public override func folderFetchCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = (errorHandler as? FetchNumberOfNewMailsOperation) else {
            Log.shared.errorAndCrash("No OP")
            return
        }
        op.handleResult(uids: notification?.userInfo?["Uids"] as? [Int])
    }

    public override func folderOpenCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = (errorHandler as? FetchNumberOfNewMailsOperation) else {
            Log.shared.errorAndCrash("No OP")
            return
        }
        op.handleFolderOpenCompleted(imapConnection: imapConnection)
    }
}