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

// MARK: - Dictionary key constants

extension MDMPredeployed {
    static let keyMDM = "mdm"
    static let keyPredeployedAccounts = "predeployedAccounts"
    static let keyServerName = "name"
    static let keyServerPort = "port"
    static let keyUserAddress = "userAddress"
    static let keyUserName = "userName"
    static let keyLoginName = "loginName"
    static let keyPassword = "password"
    static let keyImapServer = "imapServer"
    static let keySmtpServer = "smtpServer"
}

private typealias SettingsDict = [String:Any]

// MARK: - MDMPredeployedProtocol

extension MDMPredeployed: MDMPredeployedProtocol {
    func hasPredeployableAccounts() -> Bool {
        guard let mdmDict = UserDefaults.standard.dictionary(forKey: MDMPredeployed.keyMDM) else {
            return false
        }

        guard let predeployedAccounts = mdmDict[MDMPredeployed.keyPredeployedAccounts] as? [SettingsDict] else {
            return false
        }

        return !predeployedAccounts.isEmpty
    }

    /// Implementation details:
    ///
    /// From MDM-Protocol-Reference.pdf:
    ///
    /// "The configuration dictionary provides one-way communication from the MDM server to an app.
    /// An app can access its (read-only) configuration dictionary by reading the key com.apple.configuration.managed
    /// using the NSUserDefaults class."
    ///
    /// "A managed app can respond to new configurations that arrive while the app is running by observing the
    /// NSUserDefaultsDidChangeNotification notification."
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
            guard let userName = accDict[MDMPredeployed.keyUserName] as? String else {
                throw MDMPredeployedError.malformedAccountData
            }
            guard let userAddress = accDict[MDMPredeployed.keyUserAddress] as? String else {
                throw MDMPredeployedError.malformedAccountData
            }
            guard let loginName = accDict[MDMPredeployed.keyLoginName] as? String else {
                throw MDMPredeployedError.malformedAccountData
            }
            guard let password = accDict[MDMPredeployed.keyPassword] as? String else {
                throw MDMPredeployedError.malformedAccountData
            }
            guard let imapServerDict = accDict[MDMPredeployed.keyImapServer] as? SettingsDict else {
                throw MDMPredeployedError.malformedAccountData
            }
            guard let imapServerAddress = imapServerDict[MDMPredeployed.keyServerName] as? String else {
                throw MDMPredeployedError.malformedAccountData
            }
            guard let imapPortNumber = imapServerDict[MDMPredeployed.keyServerPort] as? NSNumber else {
                throw MDMPredeployedError.malformedAccountData
            }
            guard let smtpServerDict = accDict[MDMPredeployed.keySmtpServer] as? SettingsDict else {
                throw MDMPredeployedError.malformedAccountData
            }
            guard let smtpServerAddress = smtpServerDict[MDMPredeployed.keyServerName] as? String else {
                throw MDMPredeployedError.malformedAccountData
            }
            guard let smtpPortNumber = smtpServerDict[MDMPredeployed.keyServerPort] as? NSNumber else {
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

            let id = Identity.init(address: userAddress,
                                   userID: nil,
                                   addressBookID: nil,
                                   userName: userName,
                                   session: session)

            let credentials = ServerCredentials.init(loginName: loginName, clientCertificate: nil)
            credentials.password = password

            let imapServer = Server.create(serverType: .imap,
                                           port: imapPortNumber.uint16Value,
                                           address: imapServerAddress,
                                           transport: .tls,
                                           credentials: credentials)

            let smtpServer = Server.create(serverType: .smtp,
                                           port: smtpPortNumber.uint16Value,
                                           address: smtpServerAddress,
                                           transport: .tls,
                                           credentials: credentials)

            let _ = Account.init(user: id, servers: [imapServer, smtpServer], session: session)
        }
        session.commit()

        UserDefaults.standard.removeObject(forKey: MDMPredeployed.keyMDM)
        let mdmDictOpt = UserDefaults.standard.dictionary(forKey: MDMPredeployed.keyMDM)
        assert(mdmDictOpt == nil)
    }
}
