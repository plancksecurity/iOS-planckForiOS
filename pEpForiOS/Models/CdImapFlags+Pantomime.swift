//
//  CdImapFlags+Pantomime.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 21/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import UIKit

import MessageModel

extension CdImapFlags {
    open func update(cwFlags: CWFlags) {
        flagAnswered = cwFlags.contain(.answered)
        flagDraft = cwFlags.contain(.draft)
        flagFlagged = cwFlags.contain(.flagged)
        flagRecent = cwFlags.contain(.recent)
        flagSeen = cwFlags.contain(.seen)
        flagDeleted = cwFlags.contain(.deleted)
    }

    open func update(cdImapFlags: CdImapFlags) {
        flagAnswered = cdImapFlags.flagAnswered
        flagDraft = cdImapFlags.flagDraft
        flagFlagged = cdImapFlags.flagFlagged
        flagRecent = cdImapFlags.flagRecent
        flagSeen = cdImapFlags.flagSeen
        flagDeleted = cdImapFlags.flagDeleted
    }

    open func update(rawValue16: ImapFlagsBits) {
        flagAnswered = rawValue16.imapFlagBitIsSet(flagbit: .answered)
        flagDraft = rawValue16.imapFlagBitIsSet(flagbit: .draft)
        flagFlagged = rawValue16.imapFlagBitIsSet(flagbit: .flagged)
        flagRecent = rawValue16.imapFlagBitIsSet(flagbit: .recent)
        flagSeen = rawValue16.imapFlagBitIsSet(flagbit: .seen)
        flagDeleted = rawValue16.imapFlagBitIsSet(flagbit: .deleted)
    }

    open func pantomimeFlags() -> CWFlags? {
        let n = Int(rawFlagsAsShort())
        let cwFlags = CWFlags(int: n)
        return cwFlags
    }
}
