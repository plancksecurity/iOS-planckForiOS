//
//  CdImapFlags+Extension.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 21/03/2017.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import UIKit

extension CdImapFlags {
    //!!!: RM ?!
    public func imapFlags() -> ImapFlags {
        return ImapFlags(cdObject: self, context: managedObjectContext ?? Stack.shared.mainContext)
    }

    public func rawFlagsAsShort() -> Int16 {
        return ImapFlagsUtility.int16(
            answered: flagAnswered, draft: flagDraft, flagged: flagFlagged, recent: flagRecent,
            seen: flagSeen, deleted: flagDeleted)
    }

    public func imapFlagsBits() -> ImapFlagsBits {
        return rawFlagsAsShort()
    }

    public func update(cdImapFlags: CdImapFlags) {
        flagAnswered = cdImapFlags.flagAnswered
        flagDraft = cdImapFlags.flagDraft
        flagFlagged = cdImapFlags.flagFlagged
        flagRecent = cdImapFlags.flagRecent
        flagSeen = cdImapFlags.flagSeen
        flagDeleted = cdImapFlags.flagDeleted
    }

    public func update(rawValue16: ImapFlagsBits) {
        flagAnswered = rawValue16.imapFlagBitIsSet(flagbit: .answered)
        flagDraft = rawValue16.imapFlagBitIsSet(flagbit: .draft)
        flagFlagged = rawValue16.imapFlagBitIsSet(flagbit: .flagged)
        flagRecent = rawValue16.imapFlagBitIsSet(flagbit: .recent)
        flagSeen = rawValue16.imapFlagBitIsSet(flagbit: .seen)
        flagDeleted = rawValue16.imapFlagBitIsSet(flagbit: .deleted)
    }
}
