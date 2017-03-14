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


    /// Figures out whether or not a given flag bit is set
    ///
    /// - Parameter flagbit: flag bit to check state for
    /// - Returns: true if the flag bit is, no otherwize
    public func imapFlagBitIsSet(flagbit:ImapFlagBit) -> Bool {
        var isFlagBitSet = false
        if (self & flagbit.rawValue) > 0 {
            isFlagBitSet = true
        }
        return isFlagBitSet
    }


    /// Sets a certain flag-bit.
    ///
    /// - Parameter flagbit: flag to set
    public mutating func imapSetFlagBit(_ flagbit:ImapFlagBit) {
        if !imapFlagBitIsSet(flagbit: flagbit) {
            self = self ^ flagbit.rawValue
        }
    }

    /// Un-sets a certain flag-bit.
    ///
    /// - Parameter flagbit: flag to un-set
    public mutating func imapUnSetFlagBit(_ flagbit:ImapFlagBit) {
        if imapFlagBitIsSet(flagbit: flagbit) {
            self = self ^ flagbit.rawValue
        }
    }

    /// Sets a certain flag-bit.
    ///
    /// - Parameter flagbit: flag to set
    public mutating func imapToggelFlagBit(_ flagbit:ImapFlagBit) {
        if imapFlagBitIsSet(flagbit: flagbit) {
            imapUnSetFlagBit(flagbit)
        } else {
            imapSetFlagBit(flagbit)
        }
    }

    /// Returns whether or not any flag is set.
    ///
    /// - Returns: true if any flag is set, false otherwize
    public func imapAnyFlagIsSet() -> Bool {
        return !imapNoFlagSet()
    }

    /// Returns whether or not any flag is set.
    ///
    /// - Returns: true if no flag is set, false otherwize
    public func imapNoFlagSet() -> Bool {
        return self == 0
    }

    /// Returns whether or not any flag that is relevant for updating flags to server is set.
    ///
    /// - seealso: `imapRelevantFlagBits()`
    ///
    /// - Returns: true if any relevant flag is set, false otherwize
    public func imapAnyRelevantFlagSet() -> Bool {
        var anyRelevantFlagSet = false
        for flag in imapRelevantFlagBits() {
            if self.imapFlagBitIsSet(flagbit: flag) {
                anyRelevantFlagSet = true
                break
            }
        }

        return anyRelevantFlagSet
    }

    /// Returns whether or not no flag that is relevant for updating flags to server is set.
    ///
    /// - seealso: `imapRelevantFlagBits()`
    ///
    /// - Returns: true if no relevant flag is set, false otherwize
    public func imapNoRelevantFlagSet() -> Bool {
        return !imapAnyRelevantFlagSet()
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

    //        PantomimeFlagAnswered = 1,
    //        PantomimeFlagDraft = 2,
    //        PantomimeFlagFlagged = 4,
    //        PantomimeFlagRecent = 8,
    //        PantomimeFlagSeen = 16,
    //        PantomimeFlagDeleted = 32
    public func debugString() -> String {
        let str = "1 answered: \(imapFlagBitIsSet(flagbit: .answered)) " +
            "2 draft: \(imapFlagBitIsSet(flagbit: .draft)) " +
            "4 flagged: \(imapFlagBitIsSet(flagbit: .flagged)) " +
            "8 recent: \(imapFlagBitIsSet(flagbit: .recent)) " +
            "16 seen: \(imapFlagBitIsSet(flagbit: .seen)) " +
        "32 deleted: \(imapFlagBitIsSet(flagbit: .deleted))"

        return str
    }

    /// List of flags that are relevant for the app in regards of syncing with the server.
    ///
    /// Beside flagRecent, all flags are relevant as, acording to RFC3501, "This flag can not
    /// be altered by the client."
    ///
    /// -seealso: [RFC3501](https://en.wikipedia.org/wiki/Hyperlink)
    /// -returns: relevant imap flags
    private func imapRelevantFlagBits() -> [ImapFlagBit] {
        return [.answered, .draft, .flagged, .seen, .deleted]
    }
}
