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

        var uniqueRecipients = Set<Identity>()
        for recips in [theMessage.to, theMessage.cc, theMessage.bcc] {
            uniqueRecipients.formUnion(recips)
        }

        if let theFrom = theMessage.from {
            uniqueRecipients.remove(theFrom)
        }

        if theMessage.parent.folderType == .inbox {
            return uniqueRecipients.count > 1
        }

        return true
    }
}
