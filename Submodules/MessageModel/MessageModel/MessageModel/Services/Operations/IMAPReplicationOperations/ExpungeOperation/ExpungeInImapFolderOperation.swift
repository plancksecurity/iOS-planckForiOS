//
//  ExpungeInImapFolderOperation.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 19.12.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

/// Opens the folder it was created for and executes EXPUNGE,
/// making the server discard all messages in that folder that are marked with \Delete.
class ExpungeInImapFolderOperation: BaseImapFolderOperation {
    override func folderOpenCompleted(_ imapConnection: ImapConnectionProtocol) {
        syncDelegate = ExpungeInImapFolderOperationDelegate(errorHandler: self)
        self.imapConnection.delegate = syncDelegate
        do {
            try imapConnection.expunge()
        } catch {
            handle(error: error)
        }
    }

    func handleFolderExpungeCompleted() {
        waitForBackgroundTasksAndFinish()
    }
}

// MARK: - DefaultImapSyncDelegate

class ExpungeInImapFolderOperationDelegate: DefaultImapConnectionDelegate {
    override func folderExpungeCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        (errorHandler as? ExpungeInImapFolderOperation)?.handleFolderExpungeCompleted()
    }
}
