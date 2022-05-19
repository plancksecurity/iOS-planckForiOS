//
//  MDMPredeployedProtocol.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

/// Represents an MDM-configured server, e.g. an IMAP server.
struct MDMPredeployedServer {
  let host: String
  let port: UInt16
}

struct MDMPredeployedAccount {
  /// The IMAP server for this account.
  let imapServer: MDMPredeployedServer

  /// The SMTP server for this account.
  let smtpServer: MDMPredeployedServer

  /// The _login_ user name (that is, for logging in to any of the servers).
  let loginName: String

  /// The real name of the user.
  let userName: String

  /// The password to be used for all accounts.
  let password: String
}

/// Error cases thrown by MDMPredeployedProtocol.predeployAccounts.
enum MDMPredeployedError {
}

protocol MDMPredeployedProtocol {
    /// Finds out about pre-deployed accounts, and if there are any, erases the local DB and sets them up, wiping the settings that
    /// triggered the set up after that.
    ///
    /// Will be called by the app delegate _before_ any account related action has been triggered, e.g., sync services.
    ///
    /// - Note: The logins for the accounts are _not_ checked for validity, that is, a wrong password will not lead
    /// to an immediate error.
    func predeployAccounts() throws
}
