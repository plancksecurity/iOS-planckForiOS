//
//  CdImapFields+Extension.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 18/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel

extension CdImapFields {
    public static func createWithDefaults(
        in context: NSManagedObjectContext = Record.Context.default) -> CdImapFields {
        let imap = CdImapFields.create(in: context)
        imap.flagFlagged = false
        imap.flagSeen = false
        imap.flagDraft = false
        imap.flagRecent = false
        imap.flagDeleted = false
        imap.flagAnswered = false
        imap.flagsCurrent = 0
        imap.flagsFromServer = 0
        return imap
    }
}
