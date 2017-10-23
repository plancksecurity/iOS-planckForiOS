//
//  FetchOlderImapMessagesOperation.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 18.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Fetches the next bunch of messages that are older than the allready fetched ones.
public class FetchOlderImapMessagesOperation: FetchMessagesOperation {

    override func fetchMessages(_ sync: ImapSync) {
        do {
            try sync.fetchOlderMessages()
        } catch let err as NSError {
            addIMAPError(err)
            waitForBackgroundTasksToFinish()
        }
    }
}

class FetchOlderMessagesSyncDelegate: FetchMessagesSyncDelegate {
    override func folderFetchOlderNeedsRefetch(_ sync: ImapSync, notification: Notification?) {
        //BUFF: refetch
        (errorHandler as? FetchOlderImapMessagesOperation)?.fetchMessages(sync)
    }
//    public override func folderFetchCompleted(_ sync: ImapSync, notification: Notification?) {
//        (errorHandler as? FetchMessagesOperation)?.waitForBackgroundTasksToFinish()
//    }
//
//    public override func messagePrefetchCompleted(_ sync: ImapSync, notification: Notification?) {
//        // do nothing
//    }
//
//    public override func folderOpenCompleted(_ sync: ImapSync, notification: Notification?) {
//        (errorHandler as? FetchMessagesOperation)?.fetchMessages(sync)
//    }
}
