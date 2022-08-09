//
//  MDMPredeployed.swift
//  pEp
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel

// TODO: For ConnectionTransport. Eliminate?
import PantomimeFramework

class MDMPredeployed {
}

extension MDMPredeployed {
    struct AccountData {
        let accountName: String
        let email: String
        fileprivate let imapServer: AccountVerifier.ServerData
        fileprivate let smtpServer: AccountVerifier.ServerData
    }
}


// MARK: - Dictionary key constants

extension MDMPredeployed {
    /// The 'global' settings key under which all MDM settings are supposed to land.
    static let keyMDM = "com.apple.configuration.managed"

    /// The key for entry into composition settings.
    static let keyCompositionSettings = "composition_settings"

    /// The key for the sender's name, which may get used as the user's name.
    static let keyCompositionSenderName = "composition_sender_name"

    /// The key for the account description, which an absence of a better name,
    /// may get used as the user's name.
    static let keyAccountDescription = "account_description"

    /// The top-level key into MDM-deployed account settings.
    static let keyPredeployedAccounts = "pep_mail_settings"

    /// The key into the MDM settings for an account's email address.
    static let keyUserAddress = "account_email_address"

    /// The MDM settings key for the incoming mail settings.
    static let keyIncomingMailSettings = "incoming_mail_settings"

    /// The MDM settings key for an incoming server address.
    static let keyIncomingMailSettingsServer = "incoming_mail_settings_server"

    /// The MDM settings key for the connection type for an incoming server.
    ///
    /// Can be one of NONE, SSL/TLS, STARTTLS. Any other value or not providing it will default to SSL/TLS.
    static let keyIncomingMailSettingsSecurityType = "incoming_mail_settings_security_type"

    /// The MDM settings key for the incoming mail server's port.
    static let keyIncomingMailSettingsPort = "incoming_mail_settings_port"

    /// The MDM settings key for the incoming mail server's login name.
    static let keyIncomingMailSettingsUsername = "incoming_mail_settings_user_name"

    /// The MDM settings key for the outgoing mail settings.
    static let keyOutgoingMailSettings = "outgoing_mail_settings"

    /// The MDM settings key for an outgoing server address.
    static let keyOutgoingMailSettingsServer = "outgoing_mail_settings_server"

    /// The MDM settings key for the connection type for an outgoing server.
    ///
    /// Can be one of NONE, SSL/TLS, STARTTLS. Any other value or not providing it will default to STARTTLS.
    static let keyOutgoingMailSettingsSecurityType = "outgoing_mail_settings_security_type"

    /// The MDM settings key for the outgoing mail server's port.
    static let keyOutgoingMailSettingsPort = "outgoing_mail_settings_port"

    /// The MDM settings key for the outgoing mail server's login name.
    static let keyOutgoingMailSettingsUsername = "outgoing_mail_settings_user_name"
}

private typealias SettingsDict = [String:Any]

// MARK: - ServerData

extension AccountVerifier.ServerData {
    /// The MDM name for plain transport.
    static let transportPlain = "NONE"

    /// The MDM name for TLS transport.
    static let transportTLS = "SSL/TLS"

    /// The MDM name for the transport 'plain connect, followed by transition to TLS'.
    static let transportStartTLS = "STARTTLS"

    fileprivate static func from(serverSettings: SettingsDict,
                                 defaultTransport: ConnectionTransport,
                                 keyServerName: String,
                                 keyTransport: String,
                                 keyPort: String,
                                 keyLoginName: String) -> AccountVerifier.ServerData? {
        guard let serverName = serverSettings[keyServerName] as? String else {
            return nil
        }

        var transport: ConnectionTransport
        if let transportString = serverSettings[keyTransport] as? String {
            guard let theTransport = connectionTransport(fromString: transportString) else {
                return nil
            }
            transport = theTransport
        } else {
            transport = defaultTransport
        }

        guard let port = serverSettings[keyPort] as? Int else {
            return nil
        }
        guard let loginName = serverSettings[keyLoginName] as? String else {
            return nil
        }

        return AccountVerifier.ServerData(loginName: loginName,
                                          hostName: serverName,
                                          port: port,
                                          transport: transport)
    }

    private static func connectionTransport(fromString: String) -> ConnectionTransport? {
        switch (fromString) {
        case transportPlain:
            return .plain
        case transportTLS:
            return .TLS
        case transportStartTLS:
            return .startTLS
        default:
            return nil
        }
    }
}

// MARK: - MDMPredeployedProtocol

extension MDMPredeployed: MDMPredeployedProtocol {
    func accountToPredeploy() throws -> MDMPredeployed.AccountData? {
        return nil
    }

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
        let accountData: MDMPredeployed.AccountData?

        do {
            accountData = try mdmAccountToDeploy()
        } catch (let error as MDMPredeployedError) {
            callback(error)
            return
        } catch {
            callback(.malformedAccountData)
            return
        }

        // Syncronize the callbacks of all account verifications
        let group = DispatchGroup()

        // Note the first error that occurred
        var firstError: Error?

        // TODO: Get the password
        // TODO: Invoke verification

        func wipeAccounts() {
            let session = Session.main

            let allAccounts = Account.all()
            for accountToDelete in allAccounts {
                accountToDelete.delete()
            }

            session.commit()
        }

        func verify(userAddress: String,
                    username: String,
                    password: String,
                    imapServer: AccountVerifier.ServerData,
                    smtpServer: AccountVerifier.ServerData) {
            let verifier = AccountVerifier()
            group.enter()
            verifier.verify(userName: username,
                            address: userAddress,
                            password: password,
                            imapServer: imapServer,
                            smtpServer: smtpServer) { error in
                if let err = error {
                    if firstError == nil {
                        firstError = err
                    }
                }
                group.leave()
            }
        }

        // Fetch the MDM dictionary to reset in the following
        // group notification group.
        guard var mdmDict = mdmPredeploymentDictionary() else {
            return
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

    var haveAccountToPredeploy: Bool {
        do {
            let account = try mdmAccountToDeploy()
            return account != nil
        } catch {
            return false
        }
    }
}

// MARK: - Utility

extension MDMPredeployed {
    /// Loads the data from MDM for the account to be deployed.
    /// - Returns: An account, ready to be deployed, from MDM, or nil, if nothing could be found.
    /// - Throws:`MDMPredeployedError`
    private func mdmAccountToDeploy() throws -> AccountData? {
        guard let mdmDict = mdmPredeploymentDictionary() else {
            return nil
        }

        let username = mdmExtractUsername(mdmDictionary: mdmDict)

        guard let predeployedAccounts = mdmDict[MDMPredeployed.keyPredeployedAccounts] as? [SettingsDict] else {
            return nil
        }

        var serverSettings = [ServerSettings]()
        for accountDictionary in predeployedAccounts {
            guard let userAddress = accountDictionary[MDMPredeployed.keyUserAddress] as? String else {
                throw MDMPredeployedError.malformedAccountData
            }

            // Make sure there is a username, falling back to the email address if needed
            let accountUsername = username ?? userAddress

            guard let potentialServer = mdmMailSettings(accountUsername: accountUsername,
                                                        settingsDict: accountDictionary) else {
                throw MDMPredeployedError.malformedAccountData
            }

            serverSettings.append(potentialServer)
        }

        /// Invoke the given callback with pairs found in the given array and react according to its boolean result.
        ///
        /// Traversal stops if `callback` returns `false` for any of the elements, and effects the overall result.
        ///
        /// - Returns: `false` if the array contained an uneven amount of elements,
        /// or the callback returned `false`, `true` otherwise.
        func traverseInPairs<T>(elements: Array<T>, callback: (T, T) -> Bool) -> Bool {
            for i in 0..<elements.count {
                if i + 1 == elements.count {
                    return false
                }

                let e0 = elements[i]
                let e1 = elements[i+1]

                let success = callback(e0, e1)
                if !success {
                    return false
                }
            }

            return true
        }

        // Tuple of (accountName, email, imap, smtp)
        var accountDatas = [AccountData]()

        // Note that this may be overkill for just _one_ IMAP and SMTP server,
        // but it was written before that was clear, and it's still correct.
        let success = traverseInPairs(elements: serverSettings) { server0, server1 in
            switch server0 {
            case .imap(let imapAccountName, let imapEmailAddress, let serverData0):
                switch server1 {
                case .smtp(let smtpAccountName, let smtpEmailAddress, let serverData1):
                    if (imapAccountName != smtpAccountName || imapEmailAddress != smtpEmailAddress) {
                        return false
                    } else {
                        let accountData = AccountData(accountName: imapAccountName,
                                                      email: imapEmailAddress,
                                                      imapServer: serverData0,
                                                      smtpServer: serverData1)
                        accountDatas.append(accountData)
                        return true
                    }
                case .imap(_, _, _):
                    return false
                }
            case .smtp(let smtpAccountName, let smtpEmailAddress, let serverData0):
                switch server1 {
                case .smtp(_, _, _):
                    return false
                case .imap(let imapAccountName, let imapEmailAddress, let serverData1):
                    if (imapAccountName != smtpAccountName || imapEmailAddress != smtpEmailAddress) {
                        return false
                    } else {
                        let accountData = AccountData(accountName: smtpAccountName,
                                                      email: smtpEmailAddress,
                                                      imapServer: serverData1,
                                                      smtpServer: serverData0)
                        accountDatas.append(accountData)
                        return true
                    }
                }
            }
        }

        if !success {
            throw MDMPredeployedError.malformedAccountData
        }

        return accountDatas.first
    }

    private func mdmPredeploymentDictionary() -> SettingsDict? {
        // Please note the explicit use of UserDefaults for predeployment,
        // instead of the usual usage of AppSettings, since this use case is special.
        return UserDefaults.standard.dictionary(forKey: MDMPredeployed.keyMDM)
    }

    private func mdmExtractUsername(mdmDictionary: SettingsDict) -> String? {
        if let compositionSettings = mdmDictionary[MDMPredeployed.keyCompositionSettings] as? SettingsDict,
           let compositionSenderName = compositionSettings[MDMPredeployed.keyCompositionSenderName] as? String {
            return compositionSenderName
        } else {
            return mdmDictionary[MDMPredeployed.keyAccountDescription] as? String
        }
    }

    private enum ServerSettings {
        /// An IMAP server consisting of username, email address, server data.
        case imap(String, String, AccountVerifier.ServerData)

        /// An SMTP server consisting of username, email address, server data.
        case smtp(String, String, AccountVerifier.ServerData)
    }

    private func mdmMailSettings(accountUsername: String,
                                 settingsDict: SettingsDict) -> ServerSettings? {
        guard let email = settingsDict[MDMPredeployed.keyUserAddress] as? String else {
            return nil
        }

        if let imapServerSettings = settingsDict[MDMPredeployed.keyIncomingMailSettings] as? SettingsDict {
            guard let serverData = AccountVerifier.ServerData.from(serverSettings: imapServerSettings,
                                                                   defaultTransport: .TLS,
                                                                   keyServerName: MDMPredeployed.keyIncomingMailSettingsServer,
                                                                   keyTransport: MDMPredeployed.keyIncomingMailSettingsSecurityType,
                                                                   keyPort: MDMPredeployed.keyIncomingMailSettingsPort,
                                                                   keyLoginName: MDMPredeployed.keyIncomingMailSettingsUsername) else {
                return nil
            }
            return ServerSettings.imap(accountUsername, email, serverData)
        } else if let smtpServerSettings = settingsDict[MDMPredeployed.keyOutgoingMailSettings] as? SettingsDict {
            guard let serverData = AccountVerifier.ServerData.from(serverSettings: smtpServerSettings,
                                                                   defaultTransport: .startTLS,
                                                                   keyServerName: MDMPredeployed.keyOutgoingMailSettingsServer,
                                                                   keyTransport: MDMPredeployed.keyOutgoingMailSettingsSecurityType,
                                                                   keyPort: MDMPredeployed.keyOutgoingMailSettingsPort,
                                                                   keyLoginName: MDMPredeployed.keyOutgoingMailSettingsUsername) else {
                return nil
            }
            return ServerSettings.smtp(accountUsername, email, serverData)
        } else {
            return nil
        }
    }
}
