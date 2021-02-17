//
//  CdMessage+IMAP.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 02.04.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import PEPIOSToolboxForAppExtensions
#else
import pEpIOSToolbox
#endif

extension CdMessage {
    static let uidNeedsAppend = 0

    /// Use this method if you do not want the message to be moved to trash folder.
    /// Takes into account if parent folder is remote or local.
    /// Note: Use only for messages synced with an IMAP server.
    /// The caller is responsible for saving.
    func imapMarkDeleted() {
        if parentOrCrash.folderType.isSyncedWithServer {
            internalImapMarkDeleted()
        } else {
            managedObjectContext?.delete(self)
        }
    }

    /// Sets flag "deleted".
    /// Use this method if you do not want the message to be moved to trash folder.
    /// Note: Use only for messages synced with an IMAP server.
    /// The caller is responsible for saving.
    private func internalImapMarkDeleted() {
        guard self.parentOrCrash.folderType.isSyncedWithServer else {
            Log.shared.errorAndCrash(
                "This method must not be called for messages in local folders.")
            return
        }
        guard let moc = managedObjectContext else {
            // No moc. That can happenonly if the object has been deleted from moc.
            return
        }

        let theImap = imapFields(context: moc)
        theImap.localFlags?.flagDeleted = true
        imap = theImap
    }
}
