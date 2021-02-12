//
//  ReplyAlertCreator.swift
//  pEp
//
//  Created by Borja González de Pablo on 27/06/2018.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import pEpIOSToolbox

struct ReplyAlertCreator {

    public let replyAllChecker: ReplyAllPossibleCheckerProtocol
    public let alert: UIAlertController

    public init(replyAllChecker: ReplyAllPossibleCheckerProtocol) {
        self.replyAllChecker = replyAllChecker
        alert = UIUtils.actionSheet()
    }

    public func withReplyOption(
        handler: @escaping (UIAlertAction) -> Swift.Void) -> ReplyAlertCreator {
        let alertActionReply = UIAlertAction(title: NSLocalizedString("Reply",
                                                                      comment: "Message actions"),
                                             style: .default,
                                             handler: handler)
        alert.addAction(alertActionReply)
        return self
    }

    public func withReplyAllOption(handler: @escaping (UIAlertAction) -> Swift.Void) -> ReplyAlertCreator {
        if replyAllChecker.isReplyAllPossible() {
            let alertActionReplyAll = UIAlertAction(title: NSLocalizedString("Reply All",
                                                                             comment: "Message actions"),
                                                    style: .default,
                                                    handler: handler)
            alert.addAction(alertActionReplyAll)
        }
        return self
    }

    public func withFordwardOption(handler: @escaping (UIAlertAction) -> Swift.Void) -> ReplyAlertCreator {
        let alertActionForward = UIAlertAction(title: NSLocalizedString("Forward",
                                                                        comment: "Message actions"),
                                               style: .default,
                                               handler: handler)
        alert.addAction(alertActionForward)
        return self
    }

    public func withToggelMarkSeenOption(for message: Message?) -> ReplyAlertCreator {
        guard let message = message else {
            Log.shared.errorAndCrash("No Mesasge to toggel seen state for")
            return self
        }
        let text = message.imapFlags.seen ?
            NSLocalizedString("Mark as unread",
                              comment: "Email Detail View reply button menu - toggle seen state button text: unread") :
            NSLocalizedString("Mark as read",
                              comment: "Email Detail View reply button menu - toggle seen state button text: read")
        let toggleMarkSeenOption = UIAlertAction(title: text, style: .default) { (action) in
            Message.setSeenValue(to: [message],
                                 newValue: !message.imapFlags.seen)
        }
        alert.addAction(toggleMarkSeenOption)
        return self
    }

    public func withCancelOption() -> ReplyAlertCreator {
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel",
                                                                  comment: "Message actions"),
                                         style: .cancel) { (action) in }
        alert.addAction(cancelAction)
        return self
    }

    public func build() -> UIAlertController {
        return alert
    }
}
