//
//  CdImapFlags+Clone.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 29.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation
import CoreData

extension CdImapFlags {

    /// Clones this object.
    ///
    /// - note: The mandatory relationship to parent CdIMAPFields is *not* copied.
    ///
    /// - Parameters:
    ///   - context: context to work on
    ///   - deleteOriginal: if true, this object is deleted
    /// - Returns: new imap flags with booleanm flag values from this object
    func clone(context: NSManagedObjectContext, deleteOriginal: Bool = false) -> CdImapFlags {
        let clone = CdImapFlags(context: context)
        clone.updateFlagValues(withDatafrom: self)
        if deleteOriginal {
            context.delete(self)
        }
        return clone
    }

    /// Takes over all the "values" from the given object.
    private func updateFlagValues(withDatafrom flags: CdImapFlags) {
        flagAnswered = flags.flagAnswered
        flagDeleted = flags.flagDeleted
        flagDraft = flags.flagDraft
        flagFlagged = flags.flagFlagged
        flagRecent = flags.flagRecent
        flagSeen = flags.flagSeen
    }
}
