//
//  ReplyAllPossibleChecker.swift
//  pEp
//
//  Created by Dirk Zimmermann on 28.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

/**
 Determines if a reply-all is possible, or even desirable for a given message.
 */
struct ReplyAllPossibleChecker: ReplyAllPossibleCheckerProtocol {
    func isReplyAllPossible(forMessage: Message?) -> Bool {
        guard let theMessage = forMessage else {
            return false
        }

        var uniqueReplyRecipients = Set<Identity>()

        for recips in [theMessage.to, theMessage.cc, theMessage.bcc] {
            uniqueReplyRecipients.formUnion(recips)
        }

        if theMessage.parent.folderType == .inbox {
            // remove the message's account's user for the check
            if let receivingId = forMessage?.parent.account.user {
                uniqueReplyRecipients.remove(receivingId)
            }

            if let theFrom = theMessage.from {
                uniqueReplyRecipients.insert(theFrom)
            }

            return uniqueReplyRecipients.count > 1
        } else if theMessage.parent.folderType == .sent {
            // Assume that from is ourselves, and therefore all recipients
            // are eligible except our own account

            // remove the message's account's user for the check
            if let receivingId = forMessage?.parent.account.user {
                uniqueReplyRecipients.remove(receivingId)
            }

            return uniqueReplyRecipients.count > 1
        } else if theMessage.parent.folderType == .drafts {
            return false
        }

        return true
    }
}
