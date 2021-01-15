//
//  FetchOlderImapMessagesOperation.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 18.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Fetches the next bunch of older messages (older than the allready fetched ones).
class FetchOlderImapMessagesOperation: FetchMessagesInImapFolderOperation {
    override func fetchMessages(_ imapConnection: ImapConnectionProtocol) {
        do {
            try imapConnection.fetchOlderMessages()
        } catch {
            handle(error: error)
        }
    }
}
