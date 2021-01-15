//
//  CdImapFlags+TestHelper.swift
//  MessageModel
//
//  Created by Andreas Buff on 15/03/2017.
//  Copyright © 2017 pEp Security S.A. All rights reserved.
//

import MessageModel

extension CdImapFlags {
    func flagsEqual(flagBits: ImapFlagsBits?) -> Bool {
        guard let flags = flagBits else {
            return false
        }
        if flags.imapFlagBitIsSet(flagbit: .answered) && !self.flagAnswered {
            return false
        }
        if flags.imapFlagBitIsSet(flagbit: .draft) && !self.flagDraft {
            return false
        }
        if flags.imapFlagBitIsSet(flagbit: .flagged) && !self.flagFlagged {
            return false
        }
        if flags.imapFlagBitIsSet(flagbit: .recent) && !self.flagRecent {
            return false
        }
        if flags.imapFlagBitIsSet(flagbit: .seen) && !self.flagSeen {
            return false
        }
        if flags.imapFlagBitIsSet(flagbit: .deleted) && !self.flagDeleted {
            return false
        }

        return true
    }
}
