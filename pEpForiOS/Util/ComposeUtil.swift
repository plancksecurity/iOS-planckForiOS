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
    }

    static func initialTos(composeMode: ComposeMode, originalMessage om: Message) -> [Identity] { //BUFF: HERE: test .normal
        var result = [Identity]()
        switch composeMode {
        case .replyFrom:
            if om.parent.folderType == .sent || om.parent.folderType == .drafts {
                result = om.to
            } else if om.parent.folderType != .sent, let omFrom = om.from {
                result = [omFrom]
            }
        case .replyAll:
            if om.parent.folderType == .sent || om.parent.folderType == .drafts  {
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
        case .normal:
            if om.parent.folderType == .sent || om.parent.folderType == .drafts  {
                result = om.to
            }
        case .forward:
            break
        }
        return result
    }

    static func initialCcs(composeMode: ComposeMode, originalMessage om: Message) -> [Identity] {
        var result = [Identity]()
        switch composeMode {
        case .replyAll:
            if om.parent.folderType == .sent || om.parent.folderType == .drafts {
                result = om.cc
            } else {
                guard let me = initialFrom(composeMode: composeMode, originalMessage: om) else {
                    Log.shared.errorAndCrash(component: #function, errorString: "No from")
                    return result
                }
                let origCcs = om.cc
                result = origCcs.filter { $0 != me}
            }
        case .replyFrom, .forward:
            break
        case .normal:
            if om.parent.folderType == .sent || om.parent.folderType == .drafts  {
                result = om.cc
            }
        }
        return result
    }

    static func initialBccs(composeMode: ComposeMode, originalMessage om: Message) -> [Identity] {
        var result = [Identity]()
        switch composeMode {
        case .normal:
            if om.parent.folderType == .drafts || om.parent.folderType == .sent {
                result = om.bcc
            }
        case .replyFrom, .forward, .replyAll:
            break
        }
        return result
    }

    static func initialFrom(composeMode: ComposeMode, originalMessage om: Message?) -> Identity? {
        switch composeMode {
        case .replyFrom, .replyAll, .forward:
            return om?.parent.account.user
        case .normal:
            if let om = om,
                om.parent.folderType == .drafts || om.parent.folderType == .sent  {
                return om.from
            }
            return Account.defaultAccount()?.user
        }
    }
}
