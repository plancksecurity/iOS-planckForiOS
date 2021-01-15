//
//  DeleteOutdatedAutoconsumableMessagesService.swift
//  MessageModel
//
//  Created by Andreas Buff on 13.10.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

/// Deletes all messages that are:
/// * pEp-autoconsume"able
/// * outdated
class DeleteOutdatedAutoconsumableMessagesService: OperationBasedService {

    required init(backgroundTaskManager: BackgroundTaskManagerProtocol? = nil) {
        // good default for cleanup services like this one. Run once when the client calls
        // `start()` and do nothing afterwards. Run again when the client calls `start()` again.
        let runOnce = true
        super.init(runOnce: runOnce, backgroundTaskManager: backgroundTaskManager)
    }

    override func operations() -> [Operation] {
        let op = DeleteOldSyncMailsOperation()
        return [op]
    }
}
