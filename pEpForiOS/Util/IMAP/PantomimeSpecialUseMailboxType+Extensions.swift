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
    var imapSpecialUseMailboxNormal: Bool {
        return (self.rawValue ^ PantomimeSpecialUseMailboxNormal.rawValue) == 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxAll flag set.
    var imapSpecialUseMailboxAll: Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxAll.rawValue) > 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxArchive flag set.
    var imapSpecialUseMailboxArchive: Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxArchive.rawValue) > 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxDrafts flag set.
    var imapSpecialUseMailboxDrafts: Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxDrafts.rawValue) > 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxFlagged flag set.
    var imapSpecialUseMailboxFlagged: Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxFlagged.rawValue) > 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxJunk flag set.
    var imapSpecialUseMailboxJunk: Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxJunk.rawValue) > 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxSent flag set.
    var imapSpecialUseMailboxSent: Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxSent.rawValue) > 0
    }

    /// Whether or not the folder has PantomimeSpecialUseMailboxTrash flag set.
    var imapSpecialUseMailboxTrash: Bool {
        return (self.rawValue & PantomimeSpecialUseMailboxTrash.rawValue) > 0
    }
}
