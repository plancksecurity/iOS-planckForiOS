//
//  Message+IMAP.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 17.11.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

// MARK: - Deletion

extension Message {
    /// Use this method if you do not want the message to be moved to trash folder.
    /// Takes into account if parent folder is remote or local.
    public func imapMarkDeleted() {
        cdObject.imapMarkDeleted()
        moc.saveAndLogErrors()
    }
}
