//
//  CreateIMAPPlanckFolderOperationSyncDelegate.swift
//  MessageModel
//
//  Created by Martin Brude on 23/1/24.
//  Copyright © 2024 pEp Security S.A. All rights reserved.
//

import Foundation
#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif
// MARK: - DefaultImapConnectionDelegate

class CreateIMAPPlanckFolderOperationSyncDelegate: DefaultImapConnectionDelegate {
    override func folderCreateCompleted(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = errorHandler as? CreateIMAPFolderOperation else {
            Log.shared.errorAndCrash("Sorry, wrong number.")
            return
        }
        op.handleFolderCreateCompleted()
    }

    override func folderCreateFailed(_ imapConnection: ImapConnectionProtocol, notification: Notification?) {
        guard let op = errorHandler as? CreateIMAPFolderOperation else {
            Log.shared.errorAndCrash("Sorry, wrong number.")
            return
        }
        op.handleFolderCreateFailed()
    }
}
