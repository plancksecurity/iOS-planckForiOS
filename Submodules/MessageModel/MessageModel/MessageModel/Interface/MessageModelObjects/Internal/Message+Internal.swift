//
//  Message+Internal.swift
//  MessageModel
//
//  Created by Andreas Buff on 19.05.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

// MARK: - Message+Internal

extension Message {

    /// Marks all yet undecryptable message in the DB for retry decrypt. Use after getting new
    /// private key(s).
    /// - Parameters:
    ///   - account:   account whichs messages should be marked for redecrypt. If nil, all
    ///                undecryptatble messges in the database are marked.
    static func tryRedecryptYetUndecryptableMessages(for cdAaccount: CdAccount? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            let moc = Stack.shared.newPrivateConcurrentContext
            moc.performAndWait {
                CdMessage.markAllUndecryptableMessagesForRetryDecrypt(for: cdAaccount,
                                                                      context: moc)
                moc.saveAndLogErrors()
            }
        }
    }
}
