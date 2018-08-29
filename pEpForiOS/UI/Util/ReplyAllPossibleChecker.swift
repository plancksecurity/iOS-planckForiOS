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
 Determins if a reply-all is possible, or even desirable for a given message.
 */
struct ReplyAllPossibleChecker: ReplyAllPossibleCheckerProtocol {
    func isReplyAllPossible(forMessage: Message?) -> Bool {
        guard let theMessage = forMessage else {
            return false
        }

        var allRecipients = Set<Identity>()
        for recips in [theMessage.to, theMessage.cc, theMessage.bcc] {
            allRecipients.formUnion(recips)
        }

        return allRecipients.count > 1
    }
}
