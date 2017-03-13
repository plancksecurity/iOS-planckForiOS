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

    /// Returns whether or not any flag is set.
    ///
    /// - Returns: true if any flag is set, false otherwize
    public func imapAnyFlagIsSet() -> Bool {
                return !imapNoFlagSet()
    }

    /// Returns whether or not any flag that is relevant for updating flags to server is set.
    /// Relevant flags are: flagAnswered, flagDeleted, flagFlagged, flagSeen
    ///
    /// - Returns: true if any relevant flag is set, false otherwize
    public func imapAnyRelevantFlagSet() -> Bool {
        return self.imapFlagBitIsSet(flagbit: .answered) ||
            self.imapFlagBitIsSet(flagbit: .deleted) ||
            self.imapFlagBitIsSet(flagbit: .flagged) ||
            self.imapFlagBitIsSet(flagbit: .seen)
    }

    /// Returns whether or not any flag is set.
    ///
    /// - Returns: true if no flag is set, false otherwize
    public func imapNoFlagSet() -> Bool {
        return self == 0
    }

    /// Returns whether or not no flag that is relevant for updating flags to server is set.
    /// Relevant flags are: flagAnswered, flagDeleted, flagFlagged, flagSeen
    ///
    /// - Returns: true if no relevant flag is set, false otherwize
    public func imapNoRelevantFlagSet() -> Bool {
        return !self.imapFlagBitIsSet(flagbit: .answered) &&
            !self.imapFlagBitIsSet(flagbit: .deleted) &&
            !self.imapFlagBitIsSet(flagbit: .flagged) &&
            !self.imapFlagBitIsSet(flagbit: .seen)
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
