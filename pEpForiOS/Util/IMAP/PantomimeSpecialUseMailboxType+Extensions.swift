//
//  PantomimeSpecialUseMailboxType+Extensions.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 06.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

/**
 Utils to fiddle with combinable PantomimeSpecialUseMailboxType enum values.

 See: https://tools.ietf.org/html/rfc6154

 Existing IMAP (and thus Pantomime) special use types:
 PantomimeSpecialUseMailboxNormal = 0,
 PantomimeSpecialUseMailboxAll,
 PantomimeSpecialUseMailboxArchive,
 PantomimeSpecialUseMailboxDrafts,
 PantomimeSpecialUseMailboxFlagged,
 PantomimeSpecialUseMailboxJunk,
 PantomimeSpecialUseMailboxSent,
 PantomimeSpecialUseMailboxTrash
 */
extension PantomimeSpecialUseMailboxType {
    /// Whether or not the folder has no (PantomimeSpecialUseMailboxNormal) special use flag set.
    ///
    /// - Returns: true if special use flag PantomimeSpecialUseMailboxNormal is set, false otherwize
    func imapSpecialUseMailboxNormal() -> Bool {
        return (self.rawValue ^ PantomimeSpecialUseMailboxNormal.rawValue) == 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxAll flag set.
    ///
    /// - Returns: true if special use flag  PantomimeSpecialUseMailboxAll is set, false otherwize
    func imapSpecialUseMailboxAll() -> Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxAll.rawValue) > 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxArchive flag set.
    ///
    /// - Returns: true if special use flag  PantomimeSpecialUseMailboxArchive is set, false otherwize
    func imapSpecialUseMailboxArchive() -> Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxArchive.rawValue) > 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxDrafts flag set.
    ///
    /// - Returns: true if special use flag  PantomimeSpecialUseMailboxDrafts is set, false otherwize
    func imapSpecialUseMailboxDrafts() -> Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxDrafts.rawValue) > 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxFlagged flag set.
    ///
    /// - Returns: true if special use flag  PantomimeSpecialUseMailboxFlagged is set, false otherwize
    func imapSpecialUseMailboxFlagged() -> Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxFlagged.rawValue) > 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxJunk flag set.
    ///
    /// - Returns: true if special use flag  PantomimeSpecialUseMailboxJunk is set, false otherwize
    func imapSpecialUseMailboxJunk() -> Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxJunk.rawValue) > 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxSent flag set.
    ///
    /// - Returns: true if special use flag  PantomimeSpecialUseMailboxSent is set, false otherwize
    func imapSpecialUseMailboxSent() -> Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxSent.rawValue) > 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxTrash flag set.
    ///
    /// - Returns: true if special use flag  PantomimeSpecialUseMailboxTrash is set, false otherwize
    func imapSpecialUseMailboxTrash() -> Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxTrash.rawValue) > 0
    }

    /// Whether or not the folder (at least potentionally) represents a virtual mailbox.
    ///
    /// - Returns: true if special use flag  PantomimeSpecialUseMailboxTrash is set, false otherwize
    func isVirtualMailbox() -> Bool {
        return imapSpecialUseMailboxAll() || imapSpecialUseMailboxFlagged()
    }
}
