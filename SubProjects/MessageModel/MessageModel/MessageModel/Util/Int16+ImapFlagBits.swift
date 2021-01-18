//
//  Int16+ImapFlagBits.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 09/03/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

typealias ImapFlagsBits = Int16

enum ImapFlagBit: ImapFlagsBits {
    case none = 0
    case answered = 1
    case draft = 2
    case flagged = 4
    case recent = 8
    case seen = 16
    case deleted = 32
}

extension ImapFlagsBits {
    func isEmpty() -> Bool {
        return self == .none
    }

    /// Figures out whether or not a given flag bit is set
    ///
    /// - Parameter flagbit: flag bit to check state for
    /// - Returns: true if the flag bit is, no otherwize
    func imapFlagBitIsSet(flagbit:ImapFlagBit) -> Bool {
        var isFlagBitSet = false
        if (self & flagbit.rawValue) > 0 {
            isFlagBitSet = true
        }

        return isFlagBitSet
    }

    /// Sets a certain flag-bit.
    ///
    /// - Parameter flagbit: flag to set
    mutating func imapSetFlagBit(_ flagbit:ImapFlagBit) {
        if !imapFlagBitIsSet(flagbit: flagbit) {
            self = self ^ flagbit.rawValue
        }
    }

    /// Un-sets a certain flag-bit.
    ///
    /// - Parameter flagbit: flag to un-set
    mutating func imapUnSetFlagBit(_ flagbit:ImapFlagBit) {
        if imapFlagBitIsSet(flagbit: flagbit) {
            self = self ^ flagbit.rawValue
        }
    }

    /// Sets a certain flag-bit.
    ///
    /// - Parameter flagbit: flag to set
    mutating func imapToggelFlagBit(_ flagbit:ImapFlagBit) {
        if imapFlagBitIsSet(flagbit: flagbit) {
            imapUnSetFlagBit(flagbit)
        } else {
            imapSetFlagBit(flagbit)
        }
    }

    /// Returns whether or not any flag is set.
    ///
    /// - Returns: true if any flag is set, false otherwize
    func imapAnyFlagIsSet() -> Bool {
        return !imapNoFlagSet()
    }

    /// Returns whether or not any flag is set.
    ///
    /// - Returns: true if no flag is set, false otherwize
    func imapNoFlagSet() -> Bool {
        return self == ImapFlagsBits.imapNoFlagsSet()
    }



    /// Returns whether or not no flag that is relevant for updating flags to server is set.
    ///
    /// - seealso: `imapRelevantFlagBits()`
    ///
    /// - Returns: true if no relevant flag is set, false otherwize
    func imapNoRelevantFlagSet() -> Bool {
        return !imapAnyRelevantFlagSet()
    }

    static func imapAllFlagsSet() -> ImapFlagsBits {
        return ImapFlagsBits.imapNoFlagsSet() + ImapFlagBit.answered.rawValue
            + ImapFlagBit.deleted.rawValue
            + ImapFlagBit.draft.rawValue
            + ImapFlagBit.flagged.rawValue
            + ImapFlagBit.recent.rawValue
            + ImapFlagBit.seen.rawValue
    }

    static func imapNoFlagsSet() -> Int16 {
        return Int16(0)
    }

    //        PantomimeFlagAnswered = 1,
    //        PantomimeFlagDraft = 2,
    //        PantomimeFlagFlagged = 4,
    //        PantomimeFlagRecent = 8,
    //        PantomimeFlagSeen = 16,
    //        PantomimeFlagDeleted = 32
    func debugString() -> String {
        let str = "1 answered: \(imapFlagBitIsSet(flagbit: .answered)) " +
            "2 draft: \(imapFlagBitIsSet(flagbit: .draft)) " +
            "4 flagged: \(imapFlagBitIsSet(flagbit: .flagged)) " +
            "8 recent: \(imapFlagBitIsSet(flagbit: .recent)) " +
            "16 seen: \(imapFlagBitIsSet(flagbit: .seen)) " +
        "32 deleted: \(imapFlagBitIsSet(flagbit: .deleted))"

        return str
    }

    /// Figures out if the given flag is the only flag set.
    ///
    /// - Parameter flag: flag to check if ot is the only set flag
    /// - Returns: true, if given flag is set AND no other flag is set. false otherwize
    func imapOnlyFlagBitSet(is flag:ImapFlagBit) -> Bool {
        if !self.imapFlagBitIsSet(flagbit: flag) {
            return false
        }
        // we know the flagBit is set.

        var copyOfSelf = self
        copyOfSelf.imapToggelFlagBit(flag) // After toggling the flag ...

        return copyOfSelf == ImapFlagsBits.imapNoFlagsSet() // ... no flag should be set anymore
    }

    // MARK: - Relevant Flags

    /// Returns whether or not any flag that is relevant for updating flags to server is set.
    ///
    /// - seealso: `imapRelevantFlagBits()`
    ///
    /// - Returns: true if any relevant flag is set, false otherwize
    func imapAnyRelevantFlagSet() -> Bool {
        var anyRelevantFlagSet = false
        for flag in imapRelevantFlagBits() {
            if self.imapFlagBitIsSet(flagbit: flag) {
                anyRelevantFlagSet = true
                break
            }
        }

        return anyRelevantFlagSet
    }

    /// List of flags that are relevant for the app in regards of syncing with the server.
    ///
    /// Beside flagRecent, all flags are relevant as, acording to RFC3501, "This flag can not
    /// be altered by the client."
    ///
    /// - seealso: [RFC3501](https://en.wikipedia.org/wiki/Hyperlink)
    /// - returns: relevant imap flags
    private func imapRelevantFlagBits() -> [ImapFlagBit] {
        return [.answered, .draft, .flagged, .seen, .deleted]
    }
}
