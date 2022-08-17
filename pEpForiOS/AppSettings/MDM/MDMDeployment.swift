//
//  MDMDeployment.swift
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

// TODO: For ConnectionTransport. Eliminate?
import PantomimeFramework

class MDMDeployment {
}

extension MDMDeployment {
    struct AccountData {
        let accountName: String
        let email: String
        fileprivate let imapServer: AccountVerifier.ServerData
        fileprivate let smtpServer: AccountVerifier.ServerData
    }
}


// MARK: - Dictionary key constants

extension MDMDeployment {
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
    static let keyAccountDeploymentMailSettings = "pep_mail_settings"

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

    /// The MDM settings key for the incoming mail server's _login_ name.
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

    /// The MDM settings key for the outgoing mail server's _login_ name.
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

    fileprivate static func fromIncoming(serverSettings: SettingsDict) -> AccountVerifier.ServerData? {
        guard let serverName = serverSettings[MDMDeployment.keyIncomingMailSettingsServer] as? String else {
            return nil
        }

        var transport: ConnectionTransport
        if let transportString = serverSettings[MDMDeployment.keyIncomingMailSettingsSecurityType] as? String {
            guard let theTransport = connectionTransport(fromString: transportString) else {
                return nil
            }
            transport = theTransport
        } else {
            transport = .TLS
        }

        guard let port = serverSettings[MDMDeployment.keyIncomingMailSettingsPort] as? Int else {
            return nil
        }
        guard let loginName = serverSettings[MDMDeployment.keyIncomingMailSettingsUsername] as? String else {
            return nil
        }

        return AccountVerifier.ServerData(loginName: loginName,
                                          hostName: serverName,
                                          port: port,
                                          transport: transport)
    }

    fileprivate static func fromOutgoing(serverSettings: SettingsDict) -> AccountVerifier.ServerData? {
        guard let serverName = serverSettings[MDMDeployment.keyOutgoingMailSettingsServer] as? String else {
            return nil
        }

        var transport: ConnectionTransport
        if let transportString = serverSettings[MDMDeployment.keyOutgoingMailSettingsSecurityType] as? String {
            guard let theTransport = connectionTransport(fromString: transportString) else {
                return nil
            }
            transport = theTransport
        } else {
            transport = .startTLS
        }

        guard let port = serverSettings[MDMDeployment.keyOutgoingMailSettingsPort] as? Int else {
            return nil
        }
        guard let loginName = serverSettings[MDMDeployment.keyOutgoingMailSettingsUsername] as? String else {
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

// MARK: - MDMDeploymentProtocol

extension MDMDeployment: MDMDeploymentProtocol {
    func accountToDeploy() throws -> MDMDeployment.AccountData? {
        if AppSettings.shared.hasBeenMDMDeployed {
            // Deploy only once
            return nil
        }

        guard let mdmDict = mdmDeploymentDictionary() else {
            // Note, this is not considered an error. It just means there is no MDM
            // configured account.
            return nil
        }

        let username = mdmExtractUsername(mdmDictionary: mdmDict)

        guard let mailSettings = mdmDict[MDMDeployment.keyAccountDeploymentMailSettings] as? SettingsDict else {
            // Note, this is not considered an error. It just means there is no MDM
            // configured account.
            return nil
        }

        guard let userAddress = mailSettings[MDMDeployment.keyUserAddress] as? String else {
            throw MDMDeploymentError.malformedAccountData
        }

        // Make sure there is a username, falling back to the email address if needed
        let accountUsername = username ?? userAddress

        guard let incomingServerSettings = mailSettings[MDMDeployment.keyIncomingMailSettings] as? SettingsDict else {
            throw MDMDeploymentError.malformedAccountData
        }

        guard let outgoingServerSettings = mailSettings[MDMDeployment.keyOutgoingMailSettings] as? SettingsDict else {
            throw MDMDeploymentError.malformedAccountData
        }

        guard let imapServerData = AccountVerifier.ServerData.fromIncoming(serverSettings: incomingServerSettings) else {
            throw MDMDeploymentError.malformedAccountData
        }

        guard let smtpServerData = AccountVerifier.ServerData.fromOutgoing(serverSettings: outgoingServerSettings) else {
            throw MDMDeploymentError.malformedAccountData
        }

        let accountData = AccountData(accountName: accountUsername,
                                      email: userAddress,
                                      imapServer: imapServerData,
                                      smtpServer: smtpServerData)

        return accountData
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
    func deployAccount(password: String, callback: @escaping (_ error: MDMDeploymentError?) -> ()) {
        if AppSettings.shared.hasBeenMDMDeployed {
            // Deploy only once.
            callback(MDMDeploymentError.alreadyDeployed)
            return
        }

        let allAccounts = Account.all()
        if !allAccounts.isEmpty {
            // Don't overwrite any already existing accounts, are add to them.
            callback(MDMDeploymentError.localAccountsFound)
            return
        }

        let accountData: MDMDeployment.AccountData?

        do {
            accountData = try accountToDeploy()
        } catch (let error as MDMDeploymentError) {
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

        group.notify(queue: DispatchQueue.main) {
            AppSettings.shared.hasBeenMDMDeployed = true

            if let _ = firstError {
                callback(.networkError)
            } else {
                callback(nil)
            }
        }
    }

    var haveAccountToDeploy: Bool {
        do {
            let account = try accountToDeploy()
            return account != nil
        } catch {
            return false
        }
    }
}

// MARK: - Utility

extension MDMDeployment {
    private func mdmDeploymentDictionary() -> SettingsDict? {
        // Please note the explicit use of UserDefaults for deployment,
        // instead of the usual usage of AppSettings, since this use case is special.
        return UserDefaults.standard.dictionary(forKey: MDMDeployment.keyMDM)
    }

    /// Extracts the user name from composition_settings/composition_sender_name.
    /// This is recommended, but not mandatory, so the result could be nil.
    private func mdmExtractUsername(mdmDictionary: SettingsDict) -> String? {
        if let compositionSettings = mdmDictionary[MDMDeployment.keyCompositionSettings] as? SettingsDict,
           let compositionSenderName = compositionSettings[MDMDeployment.keyCompositionSenderName] as? String {
            return compositionSenderName
        } else {
            return mdmDictionary[MDMDeployment.keyAccountDescription] as? String
        }
    }
}
