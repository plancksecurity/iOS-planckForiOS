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
    static let kIncomingMailSettings = "incoming_mail_settings"

    /// The MDM settings key for an incoming server address.
    static let kIncomingMailSettingsServer = "incoming_mail_settings_server"

    /// The MDM settings key for the connection type for an incoming server.
    ///
    /// Can be one of NONE, SSL/TLS, STARTTLS. Any other value or not providing it will default to SSL/TLS.
    static let kIncomingMailSettingsSecurityType = "incoming_mail_settings_security_type"

    /// The MDM settings key for the incoming mail server's port.
    static let kIncomingMailSettingsPort = "incoming_mail_settings_port"

    static let keyServerName = "name"
    static let keyServerPort = "port"

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

        let username = mdmExtractUsername(mdmDictionary: mdmDict)

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
            guard let userAddress = accountDictionary[MDMPredeployed.keyUserAddress] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }

            // Make sure there is a username, falling back to the email address if needed
            let accountUsername = username ?? userAddress

            guard let loginName = accountDictionary[MDMPredeployed.keyLoginName] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let password = accountDictionary[MDMPredeployed.keyPassword] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let imapServerDict = accountDictionary[MDMPredeployed.kIncomingMailSettings] as? SettingsDict else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let imapServerAddress = imapServerDict[MDMPredeployed.kIncomingMailSettingsServer] as? String else {
                callback(MDMPredeployedError.malformedAccountData)
                return
            }
            guard let imapPortNumber = imapServerDict[MDMPredeployed.kIncomingMailSettingsPort] as? NSNumber else {
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
                            userName: accountUsername,
                            password: password,
                            loginName: loginName,
                            serverIMAP: imapServerAddress,
                            portIMAP: UInt16(imapPortNumber.int16Value),
                            transportStringIMAP: "SSL/TLS",
                            serverSMTP: smtpServerAddress,
                            portSMTP: UInt16(smtpPortNumber.int16Value),
                            transportStringSMTP: "SSL/TLS") { error in
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

    private struct ServerData {
        let hostName: String
        let port: UInt16

        /// - Note: Can only be "NONE", "SSL/TLS" or "STARTTLS".
        let transportString: String

        let loginName: String

        private static let legitTransports: Set = ["NONE", "SSL/TLS", "STARTTLS"]

        init?(hostName: String, port: Int, transportString: String, loginName: String) {
            self.port = UInt16(port)
            if Int(self.port) != port {
                return nil
            }

            if ServerData.legitTransports.contains(transportString) {
                self.transportString = transportString
            } else {
                return nil
            }

            self.hostName = hostName
            self.loginName = loginName
        }

        static func from(serverSettings: SettingsDict) -> ServerData? {
            guard let serverName = serverSettings["incoming_mail_settings_server"] as? String else {
                return nil
            }
            let transportString = serverSettings["incoming_mail_settings_security_type"] as? String ?? "NONE"
            guard let port = serverSettings["incoming_mail_settings_port"] as? Int else {
                return nil
            }
            guard let loginName = serverSettings["incoming_mail_settings_user_name"] as? String else {
                return nil
            }

            return ServerData(hostName: serverName,
                              port: port,
                              transportString: transportString,
                              loginName: loginName)
        }
    }

    private enum ServerSettings {
        case imap(String, ServerData)
        case smtp(String, ServerData)
    }

    private func mdmPEPMailSettings(settingsDict: SettingsDict) -> ServerSettings? {
        guard let email = settingsDict["account_email_address"] as? String else {
            return nil
        }

        if let imapServerSettings = settingsDict["incoming_mail_settings"] as? SettingsDict {
            guard let serverData = ServerData.from(serverSettings: imapServerSettings) else {
                return nil
            }
            return ServerSettings.imap(email, serverData)
        } else if let smtpServerSettings = settingsDict["outgoing_mail_settings"] as? SettingsDict {
            guard let serverData = ServerData.from(serverSettings: smtpServerSettings) else {
                return nil
            }
            return ServerSettings.smtp(email, serverData)
        } else {
            return nil
        }
    }
}
