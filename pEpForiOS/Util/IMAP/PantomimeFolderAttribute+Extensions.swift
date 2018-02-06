//
//  PantomimeFolderAttribute+Extensions.swift
//  pEp
//
//  Created by Andreas Buff on 06.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

/**
 Utils to fiddle with combinable PantomimeFolderAttribute enum values.

 Existing IMAP (and thus Pantomime) folder attributes:
 PantomimeHoldsFolders = 1,
 PantomimeHoldsMessages = 2,
 PantomimeNoInferiors = 4,
 PantomimeNoSelect = 8,
 PantomimeMarked = 16,
 PantomimeUnmarked = 32
 */
extension PantomimeFolderAttribute {

    /// Whether or not the folder is able to hold (sub)folders
    ///
    /// - Returns: true if HoldsFolders attribute is set, false otherwize
    func imapAttributeHoldsFolders() -> Bool {
        return (self.rawValue & PantomimeHoldsFolders.rawValue) > 0
    }

    /// Whether or not the folder is able to hold meaages.
    ///
    /// - Returns: true if HoldsMessages attribute is set, false otherwize
    func imapAttributeHoldsMessages() -> Bool {
        return (self.rawValue & PantomimeHoldsMessages.rawValue) > 0
    }

    /// Whether or not the NoInferiors attribute is set.
    ///
    /// - Returns: true if NoInferiors attribute is set, false otherwize
    func imapAttributeNoInferiors() -> Bool {
        return (self.rawValue & PantomimeNoInferiors.rawValue) > 0
    }

    /// Whether or not the NoSelect attribute is set.
    ///
    /// - Returns: true if NoSelect attribute is set, false otherwize
    func imapAttributeNoSelect() -> Bool {
        return (self.rawValue & PantomimeNoSelect.rawValue) > 0
    }

    /// Whether or not the folder is marked.
    ///
    /// - Returns: true if PantomimeMarked attribute is set, false otherwize
    func imapAttributeMarked() -> Bool {
        return (self.rawValue & PantomimeMarked.rawValue) > 0
    }

    /// Whether or not the folder is unmarked.
    ///
    /// - Returns: true if PantomimeUnmarked attribute is set, false otherwize
    func imapAttributeUnmarked() -> Bool {
        return (self.rawValue & PantomimeUnmarked.rawValue) > 0
    }

    /// Whether or not the attribute marks as selectable.
    ///
    /// - Returns: false, if attribute "\NoSelect" is set, true otherwize
    func isSelectable() -> Bool {
        if self.imapAttributeNoSelect() {
            return false
        }
        return true
    }
}
