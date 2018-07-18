//
//  ComposeUtil.swift
//  pEp
//
//  Created by Andreas Buff on 18.07.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import MessageModel

/// Utils for composing (reply, replyAll ...) a message. Helps finding out the correct recipients.
struct ComposeUtil {

    enum ComposeMode {
        case normal
        case replyFrom
        case replyAll
        case forward
        case draft
    }

    static func initialTos(composeMode: ComposeMode, originalMessage om: Message) -> [Identity] {
        var result = [Identity]()
        switch composeMode {
        case .draft:
            result = om.to
        case .replyFrom:
            if om.parent.folderType == .sent {
                result = om.to
            } else if om.parent.folderType != .sent, let omFrom = om.from {
                result = [omFrom]
            }
        case .replyAll:
            if om.parent.folderType == .sent {
                result = om.to
            } else if om.parent.folderType != .sent, let omFrom = om.from {
                guard let me = initialFrom(composeMode: composeMode, originalMessage: om) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No from")
                    return result
                }
                let origTos = om.to
                let originalTosWithoutMe = origTos.filter { $0 != me}
                result = originalTosWithoutMe + [omFrom]
            }
        case .normal, .forward:
            break
        }
        return result
    }

    static func initialCcs(composeMode: ComposeMode, originalMessage om: Message) -> [Identity] {
        var result = [Identity]()
        switch composeMode {
        case .draft:
            result = om.cc
        case .replyFrom:
            return result
        case .replyAll:
            if om.parent.folderType == .sent {
                result = om.cc
            } else if om.parent.folderType != .sent {
                guard let me = initialFrom(composeMode: composeMode, originalMessage: om) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No from")
                    return result
                }
                let origCcs = om.cc
                result = origCcs.filter { $0 != me}
            }
        case .normal, .forward:
            break
        }
        return result
    }

    static func initialBccs(composeMode: ComposeMode, originalMessage om: Message) -> [Identity] {
        var result = [Identity]()
        switch composeMode {
        case .draft:
            result = om.bcc
        case .normal, .forward, .replyAll, .replyFrom:
            break
        }
        return result
    }

    static func initialFrom(composeMode: ComposeMode, originalMessage om: Message?) -> Identity? {
        switch composeMode {
        case .draft:
            return om?.from
        case .replyFrom:
            return om?.parent.account.user
        case .replyAll:
            return om?.parent.account.user
        case .forward:
            return om?.parent.account.user
        case .normal:
            return Account.defaultAccount()?.user
        }
    }
}
