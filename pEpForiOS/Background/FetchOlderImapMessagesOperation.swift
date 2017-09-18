//
//  FetchOlderImapMessagesOperation.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 18.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Fetches a bunch of messages that are older than the allready fetched ones.
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
