//
//  MDMPredeployed.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

class MDMPredeployed {
}

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
