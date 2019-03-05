//
//  FetchOlderImapMessagesOperation.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 18.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/// Fetches the next bunch of older messages (older than the allready fetched ones).
public class FetchOlderImapMessagesOperation: FetchMessagesOperation {
    override open func fetchMessages(_ sync: ImapSync) {
        do {
            try sync.fetchOlderMessages()
        } catch {
            addIMAPError(error)
            waitForBackgroundTasksToFinish()
        }
    }
}
