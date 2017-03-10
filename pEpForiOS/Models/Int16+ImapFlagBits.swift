//
//  Int16+ImapFlagBits.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 09/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

public enum ImapFlagBit: Int16 {
    case answered = 1
    case draft = 2
    case flagged = 4
    case recent = 8
    case seen = 16
    case deleted = 32
}

extension Int16 {
    public func imapFlagBitIsSet(flagbit:ImapFlagBit) -> Bool {
        var isFlagBitSet = false
        if (self & flagbit.rawValue) > 0 {
            isFlagBitSet = true
        }
        return isFlagBitSet
    }

    public func imapAnyFlagIsSet() -> Bool {
                return !imapNoFlagSet()
    }

    public func imapNoFlagSet() -> Bool {
        return self == 0
    }

    static public func imapAllFlagsSet() -> Int16 {
        return Int16(0) + ImapFlagBit.answered.rawValue
            + ImapFlagBit.deleted.rawValue
            + ImapFlagBit.draft.rawValue
            + ImapFlagBit.flagged.rawValue
            + ImapFlagBit.recent.rawValue
            + ImapFlagBit.seen.rawValue
    }

    static public func imapNoFlagsSet() -> Int16 {
        return Int16(0)
    }
}
