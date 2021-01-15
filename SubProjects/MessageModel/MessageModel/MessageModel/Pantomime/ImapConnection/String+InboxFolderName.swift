//
//  String+InboxFolderName.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 29.01.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension String {
    /// - Returns: True if this string looks like the INBOX folder name, false
    ///   if it doesn't.
    func isInboxFolderName() -> Bool {
        if lowercased() == ImapConnection.defaultInboxName.lowercased() {
            return true
        }
        return false
    }
}
