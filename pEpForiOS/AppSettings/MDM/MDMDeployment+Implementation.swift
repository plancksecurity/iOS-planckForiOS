//
//  MDMDeployment+Implementation.swift
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

extension MDMDeployment {
    struct AccountData {
        let accountName: String
        let email: String
        fileprivate let imapServer: AccountVerifier.ServerData
        fileprivate let smtpServer: AccountVerifier.ServerData
    }
}

// MARK: - Dictionary key constants

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
        if !AppSettings.shared.mdmIsEnabled {
            // No MDM deployment if MDM is not supposed to be used
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
    func deployAccount(password: String,
                       accountVerifier: AccountVerifierProtocol = AccountVerifier(),
                       callback: @escaping (_ error: MDMDeploymentError?) -> ()) {
        let allAccounts = Account.all()
        if !allAccounts.isEmpty {
            // Finding existing accounts is an error
            callback(MDMDeploymentError.localAccountsFound)
            return
        }

        let maybeAccountData: MDMDeployment.AccountData?

        do {
            maybeAccountData = try accountToDeploy()
        } catch (let error as MDMDeploymentError) {
            callback(error)
            return
        } catch {
            callback(.malformedAccountData)
            return
        }

        guard let accountData = maybeAccountData else {
            callback(.malformedAccountData)
            return
        }

        let usePEPFolder = AppSettings.shared.mdmPEPSyncFolderEnabled

        accountVerifier.verify(userName: accountData.accountName,
                               address: accountData.email,
                               password: password,
                               imapServer: accountData.imapServer,
                               smtpServer: accountData.smtpServer,
                               usePEPFolder: usePEPFolder) { error in
            if let generalError = error {
                var isAuthError = false

                if let imapError = generalError as? ImapSyncOperationError {
                    switch imapError {
                    case .authenticationFailed(_, _):
                        isAuthError = true
                    default:
                        break
                    }
                }

                if let smtpError = generalError as? SmtpSendError {
                    switch smtpError {
                    case .authenticationFailed(_, _):
                        isAuthError = true
                    default:
                        break
                    }
                }

                if isAuthError {
                    callback(.authenticationError)
                } else {
                    callback(.networkError)
                }
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

// MARK: - JSON

extension MDMDeployment {
    /// - returns: The MDM dictionary as json,  pretty printed.
    /// If there is no dictionary yet, "No dictionary" is return.
    /// If serialization fails, returns "No data".
    /// if there is an error converting data to string, "No pretty dictionary" is returned.
    public func mdmPrettyPrintedDictionary() -> String {
        guard let dict = UserDefaults.standard.dictionary(forKey: MDMDeployment.keyMDM) else {
            return NSLocalizedString("No dictionary", comment: "No dictionary error")
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) else {
            return NSLocalizedString("No data", comment: "No data error")
        }
        guard let prettyMDMDictionary = String(data: data, encoding: .utf8) else {
            return NSLocalizedString("No pretty dictionary", comment: "No pretty dictionary error")
        }
        return prettyMDMDictionary
    }
}

// MARK: - Internal Utility

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
           let compositionSenderName = compositionSettings[AppSettings.keyCompositionSenderName] as? String {
            return compositionSenderName
        } else {
            return mdmDictionary[MDMDeployment.keyAccountDescription] as? String
        }
    }
}
