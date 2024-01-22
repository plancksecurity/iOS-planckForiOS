//
//  CreateIMAPFolderOperationSyncDelegate.swift
//  MessageModel
//
//  Created by Martin Brude on 22/1/24.
//  Copyright © 2024 pEp Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

// MARK: - DefaultImapSyncDelegate

class CreateIMAPFolderOperationSyncDelegate<T: CreateIMAPFolderOperation>: DefaultImapConnectionDelegate {
    
    private weak var operation: T?

    init(operation: T, errorHandler: ImapConnectionDelegateErrorHandlerProtocol) {
        self.operation = operation
        super.init(errorHandler: errorHandler)
    }

    override func folderCreateCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = operation else {
            Log.shared.errorAndCrash("Sorry, wrong number.")
            return
        }
        Log.shared.info("******* Finished:", op.name!)
        op.handleFolderCreateCompleted()
    }

    override func folderCreateFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = operation else {
            Log.shared.errorAndCrash("Sorry, wrong number.")
            return
        }
        op.handleFolderCreateFailed()
    }
}

