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
    static let keyMDM = "com.apple.configuration.managed"
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
    /// Implementation details:
    ///
    /// From MDM-Protocol-Reference.pdf, p 70:
    ///
    /// "The configuration dictionary provides one-way communication from the MDM server to an app.
    /// An app can access its (read-only) configuration dictionary by reading the key com.apple.configuration.managed
    /// using the NSUserDefaults class."
    ///
    /// "A managed app can respond to new configurations that arrive while the app is running by observing the
    /// NSUserDefaultsDidChangeNotification notification."
    func predeployAccounts(callback: (_ error: MDMPredeployedError?) -> ()) {
        guard var mdmDict = UserDefaults.standard.dictionary(forKey: MDMPredeployed.keyMDM) else {
            callback(nil)
            return
        }

        guard let predeployedAccounts = mdmDict[MDMPredeployed.keyPredeployedAccounts] as? [SettingsDict] else {
            callback(nil)
            return
        }

        var haveWipedExistingAccounts = false
        for accDict in predeployedAccounts {
            guard let userName = accDict[MDMPredeployed.keyUserName] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let userAddress = accDict[MDMPredeployed.keyUserAddress] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let loginName = accDict[MDMPredeployed.keyLoginName] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let password = accDict[MDMPredeployed.keyPassword] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let imapServerDict = accDict[MDMPredeployed.keyImapServer] as? SettingsDict else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let imapServerAddress = imapServerDict[MDMPredeployed.keyServerName] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let imapPortNumber = imapServerDict[MDMPredeployed.keyServerPort] as? NSNumber else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let smtpServerDict = accDict[MDMPredeployed.keySmtpServer] as? SettingsDict else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let smtpServerAddress = smtpServerDict[MDMPredeployed.keyServerName] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let smtpPortNumber = smtpServerDict[MDMPredeployed.keyServerPort] as? NSNumber else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }

            if !haveWipedExistingAccounts {
                let session = Session.main

                let allAccounts = Account.all()
                for accountToDelete in allAccounts {
                    accountToDelete.delete()
                }

                session.commit()

                haveWipedExistingAccounts = true
            }
        }

        mdmDict[MDMPredeployed.keyPredeployedAccounts] = nil
        UserDefaults.standard.set(mdmDict, forKey: MDMPredeployed.keyMDM)

        callback(nil)
    }
}
