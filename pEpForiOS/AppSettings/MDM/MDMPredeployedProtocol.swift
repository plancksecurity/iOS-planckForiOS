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
  /// If non-nil, this means that this account is IMAP based.
  let imapServer: MDMPredeployedServer?

  /// There is currently always an SMTP server, but who knows?
  let smtpServer: MDMPredeployedServer?

  /// The _login_ user name (that is, for logging in to any of the servers).
  let loginName: String

  /// The real name of the user.
  let userName: String

  /// The password to be used for all accounts.
  /// Can be nil, in which case OAuth2 has to be used.
  /// Note that in this case, the user has to enter a password.
  let password: String?
}

protocol MDMPredeployedProtocol {
}
