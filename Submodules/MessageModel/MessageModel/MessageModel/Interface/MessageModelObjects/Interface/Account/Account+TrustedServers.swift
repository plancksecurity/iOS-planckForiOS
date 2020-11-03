//
//  Account+TrustedServers.swift
//  MessageModel
//
//  Created by Alejandro Gelos on 14/01/2020.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

extension Account {
    /// Indicate if you should show a warning before trusting this account
    public var shouldShowWaringnBeforeTrusting: Bool {
        guard let imapServer = imapServer else {
            Log.shared.errorAndCrash("No imap server while trying to trust this account")
            return false
        }
        return imapServer.shouldShowWaringnBeforeTrusting
    }
}
