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

        let username = mdmExtractUsername(mdmDictionary: mdmDict)

        guard let predeployedAccounts = mdmDict[MDMPredeployed.keyPredeployedAccounts] as? [SettingsDict] else {
            callback(nil)
            return
        }

        // Syncronize the callbacks of all account verifications
        let group = DispatchGroup()

        // Note the first error that occurred
        var firstError: Error?

        var serverSettings = [ServerSettings]()
        for accountDictionary in predeployedAccounts {
            guard let userAddress = accountDictionary[MDMPredeployed.keyUserAddress] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }

            // Make sure there is a username, falling back to the email address if needed
            let accountUsername = username ?? userAddress

            guard let potentialServer = mdmMailSettings(accountUsername: accountUsername,
                                                        settingsDict: accountDictionary) else {
                callback(MDMPredeployedError.malformedAccountData)
                return
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

        // Pairs of (imap, smtp)
        var serverPairs = [(ServerSettings, ServerSettings)]()

        let success = traverseInPairs(elements: serverSettings) { server0, server1 in
            switch server0 {
            case .imap(let imapAccountName, let imapEmailAddress, _):
                switch server1 {
                case .smtp(let smtpAccountName, let smtpEmailAddress, _):
                    if (imapAccountName != smtpAccountName || imapEmailAddress != smtpEmailAddress) {
                        return false
                    } else {
                        serverPairs.append((server0, server1))
                        return true
                    }
                case .imap(_, _, _):
                    return false
                }
            case .smtp(let smtpAccountName, let smtpEmailAddress, _):
                switch server1 {
                case .smtp(_, _, _):
                    return false
                case .imap(let imapAccountName, let imapEmailAddress, _):
                    if (imapAccountName != smtpAccountName || imapEmailAddress != smtpEmailAddress) {
                        return false
                    } else {
                        serverPairs.append((server1, server0))
                        return true
                    }
                }
            }
        }

        if !success {
            callback(MDMPredeployedError.malformedAccountData)
            return
        }

        for (imap, smtp) in serverPairs {
            switch imap {
            case .smtp(_, _, _):
                // This should not happen anymore, we already checked,
                // but make the compiler happy.
                callback(MDMPredeployedError.malformedAccountData)
                return
            case .imap(let imapAccountName, let imapEmailAddress, let imapServer):
                switch smtp {
                case .imap(_, _, _):
                    // This should not happen anymore, we already checked,
                    // but make the compiler happy.
                    callback(MDMPredeployedError.malformedAccountData)
                    return
                case .smtp(_, _, let smtpServer):
                    // Note that we already checked that the account name and email address
                    // are the same for both IMAP and SMTP, so we only need the IMAP version.

                    // TODO: Invoke verification
                    break
                }
            }
        }

        func wipeAccounts() {
            let session = Session.main

            let allAccounts = Account.all()
            for accountToDelete in allAccounts {
                accountToDelete.delete()
            }

            session.commit()
        }

        func verify(userAddress: String,
                    userName: String,
                    loginName: String,
                    password: String,
                    imapServerAddress: String,
                    imapPortNumber: NSNumber,
                    smtpServerAddress: String,
                    smtpPortNumber: NSNumber) {
            let verifier = AccountVerifier()
            group.enter()
            verifier.verify(address: userAddress,
                            userName: "TODO: accountUsername",
                            password: password,
                            loginName: loginName,
                            serverIMAP: imapServerAddress,
                            portIMAP: UInt16(imapPortNumber.int16Value),
                            transportStringIMAP: "TODO",
                            serverSMTP: smtpServerAddress,
                            portSMTP: UInt16(smtpPortNumber.int16Value),
                            transportStringSMTP: "TODO") { error in
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
