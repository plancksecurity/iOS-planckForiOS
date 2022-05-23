//
//  MDMPredeployed.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

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

typealias SettingsDict = [String:Any]

extension MDMPredeployed: MDMPredeployedProtocol {
    static let keyMDM = "mdm"
    static let keyPredeployedAccounts = "predeployedAccounts"
    static let keyServerName = "name"
    static let keyServerPort = "port"
    static let keyUserName = "userName"
    static let keyLoginName = "loginName"
    static let keyPassword = "password"
    static let keyImapServer = "imapServer"
    static let keySmtpServer = "smtpServer"

    func predeployAccounts() throws {
        guard let mdmDict = UserDefaults.standard.dictionary(forKey: MDMPredeployed.keyMDM) else {
            return
        }

        guard let predeployedAccounts = mdmDict[MDMPredeployed.keyPredeployedAccounts] as? [SettingsDict] else {
            return
        }

        let session = Session.main

        var haveWipedExistingAccounts = false
        for accDict in predeployedAccounts {
            guard let imapServerDict = accDict[MDMPredeployed.keyImapServer] else {
                throw MDMPredeployedError.malformedAccountData
            }
            guard let smtpServerDict = accDict[MDMPredeployed.keySmtpServer] else {
                throw MDMPredeployedError.malformedAccountData
            }
            guard let userName = accDict[MDMPredeployed.keyUserName] else {
                throw MDMPredeployedError.malformedAccountData
            }
            guard let loginName = accDict[MDMPredeployed.keyLoginName] else {
                throw MDMPredeployedError.malformedAccountData
            }
            guard let password = accDict[MDMPredeployed.keyPassword] else {
                throw MDMPredeployedError.malformedAccountData
            }

            if !haveWipedExistingAccounts {
                let allAccounts = Account.all()
                for accountToDelete in allAccounts {
                    accountToDelete.delete()
                }

                session.commit()

                haveWipedExistingAccounts = true
            }
        }
    }
}
