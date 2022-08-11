//
//  MDMPredeployed.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

#if EXT_SHARE
import MessageModelForAppExtensions
#else
import MessageModel
#endif

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
    func predeployAccounts(callback: @escaping (_ error: MDMPredeployedError?) -> ()) {
        guard var mdmDict = mdmPredeploymentDictionary() else {
            callback(nil)
            return
        }

        guard let predeployedAccounts = mdmDict[MDMPredeployed.keyPredeployedAccounts] as? [SettingsDict] else {
            callback(nil)
            return
        }

        // Syncronize the callbacks of all account verifications
        let group = DispatchGroup()

        // Note the first error that occurred
        var firstError: Error?

        var haveWipedExistingAccounts = false
        for accountDictionary in predeployedAccounts {
            guard let userName = accountDictionary[MDMPredeployed.keyUserName] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let userAddress = accountDictionary[MDMPredeployed.keyUserAddress] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let loginName = accountDictionary[MDMPredeployed.keyLoginName] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let password = accountDictionary[MDMPredeployed.keyPassword] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let imapServerDict = accountDictionary[MDMPredeployed.keyImapServer] as? SettingsDict else {
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
            guard let smtpServerDict = accountDictionary[MDMPredeployed.keySmtpServer] as? SettingsDict else {
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

            let verifier = AccountVerifier()
            group.enter()
            verifier.verify(address: userAddress,
                            userName: userName,
                            password: password,
                            loginName: loginName,
                            serverIMAP: imapServerAddress,
                            portIMAP: UInt16(imapPortNumber.int16Value),
                            serverSMTP: smtpServerAddress,
                            portSMTP: UInt16(smtpPortNumber.int16Value)) { error in
                if let err = error {
                    if firstError == nil {
                        firstError = err
                    }
                }
                group.leave()
            }
        }

        group.notify(queue: DispatchQueue.main) {
            // Overwrite the accounts to deploy with nil
            // Please note the explicit use of UserDefaults,
            // instead of the usual usage of AppSettings, since this use case is special.
            mdmDict[MDMPredeployed.keyPredeployedAccounts] = nil
            UserDefaults.standard.set(mdmDict, forKey: MDMPredeployed.keyMDM)

            if let _ = firstError {
                callback(.networkError)
            } else {
                callback(nil)
            }
        }
    }

    var haveAccountsToPredeploy: Bool {
        guard let mdmDict = mdmPredeploymentDictionary() else {
            return false
        }

        guard let predeployedAccounts = mdmDict[MDMPredeployed.keyPredeployedAccounts] as? [SettingsDict] else {
            return false
        }

        return !predeployedAccounts.isEmpty
    }

    private func mdmPredeploymentDictionary() -> [String : Any]? {
        // Please note the explicit use of UserDefaults for predeployment,
        // instead of the usual usage of AppSettings, since this use case is special.
        return UserDefaults.standard.dictionary(forKey: MDMPredeployed.keyMDM)
    }
}
