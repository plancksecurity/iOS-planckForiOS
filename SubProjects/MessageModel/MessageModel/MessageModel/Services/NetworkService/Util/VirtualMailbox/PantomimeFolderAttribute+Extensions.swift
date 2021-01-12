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

import PantomimeFramework

extension PantomimeFolderAttribute {

    /// Whether or not the folder is able to hold (sub)folders
    var imapAttributeHoldsFolders: Bool {
        return (self.rawValue & PantomimeHoldsFolders.rawValue) > 0
    }

    /// Whether or not the folder is able to hold meaages.
    var imapAttributeHoldsMessages: Bool {
        return (self.rawValue & PantomimeHoldsMessages.rawValue) > 0
    }

    /// Whether or not the NoInferiors attribute is set.
    var imapAttributeNoInferiors: Bool {
        return (self.rawValue & PantomimeNoInferiors.rawValue) > 0
    }

    /// Whether or not the NoSelect attribute is set.
    var imapAttributeNoSelect: Bool {
        return (self.rawValue & PantomimeNoSelect.rawValue) > 0
    }

    /// Whether or not the folder is marked.
    var imapAttributeMarked: Bool {
        return (self.rawValue & PantomimeMarked.rawValue) > 0
    }

    /// Whether or not the folder is unmarked.
    var imapAttributeUnmarked: Bool {
        return (self.rawValue & PantomimeUnmarked.rawValue) > 0
    }

    /// Whether or not the attribute marks as selectable.
    var isSelectable: Bool {
        return !self.imapAttributeNoSelect
    }
}
