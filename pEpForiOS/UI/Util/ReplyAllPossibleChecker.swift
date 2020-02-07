//
//  ReplyAllPossibleChecker.swift
//  pEp
//
//  Created by Dirk Zimmermann on 28.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/// Determines if a reply-all is possible, or even desirable for a given message.
struct ReplyAllPossibleChecker: ReplyAllPossibleCheckerProtocol {
    private let message: Message
    init(messageToReplyTo: Message) {
        self.message = messageToReplyTo
    }

    func isReplyAllPossible() -> Bool {
        var uniqueReplyRecipients = Set<Identity>()

        for recips in [message.to, message.cc, message.bcc] {
            uniqueReplyRecipients.formUnion(recips)
        }

        if message.parent.folderType == .inbox {
            // remove the message's account's user for the check
            let receivingId = message.parent.account.user
            uniqueReplyRecipients.remove(receivingId)

            if let theFrom = message.from {
                uniqueReplyRecipients.insert(theFrom)
            }

            return uniqueReplyRecipients.count > 1
        } else if message.parent.folderType == .sent {
            // Assume that from is ourselves, and therefore all recipients
            // are eligible except our own account

            // remove the message's account's user for the check
            let receivingId = message.parent.account.user
            uniqueReplyRecipients.remove(receivingId)

            return uniqueReplyRecipients.count > 1
        } else if message.parent.folderType == .drafts {
            return false
        }

        return true
    }
}
