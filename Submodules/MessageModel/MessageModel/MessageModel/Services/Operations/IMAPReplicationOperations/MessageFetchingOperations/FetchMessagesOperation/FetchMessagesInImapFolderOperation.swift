//
//  FetchMessagesOperation.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 15/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import CoreData

/// Fetches new messages for one folder from the IMAP server
class FetchMessagesInImapFolderOperation: BaseImapFolderOperation {
    func fetchMessages(_ imapConnection: ImapConnectionProtocol) {
        do {
            try imapConnection.fetchMessages()
        } catch {
            handle(error: error)
        }
    }

    fileprivate func handleFolderFetchCompleted() {
        // Nothing else to do here. PersistantImapFolder is responsible for saving fetched messages
        waitForBackgroundTasksAndFinish()
    }

    override func folderOpenCompleted(_ imapConnection: ImapConnectionProtocol) {
        syncDelegate = FetchMessagesInImapFolderOperationSyncDelegate(errorHandler: self)
        self.imapConnection.delegate = syncDelegate
        fetchMessages(imapConnection)
    }
}

// MARK: - DefaultImapSyncDelegate

class FetchMessagesInImapFolderOperationSyncDelegate: DefaultImapConnectionDelegate {
    public override func folderFetchCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        (errorHandler as? FetchMessagesInImapFolderOperation)?.handleFolderFetchCompleted()
    }

    public override func messagePrefetchCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        // do nothing //???: why is that called? Looks wrong. If you know why, please leave explanation here.
    }
}
