//
//  MDMAccountPredeploymentViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

class MDMAccountPredeploymentViewModel {
    /// Checks for predeployed accounts, and acts on them.
    ///
    /// - Note: Silently fails if there was an error is the account description.
    func predeployAccounts(callback: (_ predeploymentError: MDMPredeployedError?) -> ()) {
        if !AppSettings.shared.mdmPredeployAccounts {
            return
        }

        let predeployer: MDMPredeployedProtocol = MDMPredeployed()
        predeployer.predeployAccounts { maybeError in
            if let error = maybeError {
                callback(error)
            } else if let error = maybeError {
                // This should not happen
                Log.shared.errorAndCrash(error: error)
            } else {
                callback(nil)
            }
        }
    }
}

// MARK: - TMP Testing

private typealias SettingsDict = [String:Any]

extension MDMAccountPredeploymentViewModel {
    static func addTestData() {
        AppSettings.shared.mdmPredeployAccounts = true

        let server = "server.example.com"
        let email = "email@\(server)"

        predeployAccount(userName: "User Name",
                         userAddress: email,
                         loginName: email,
                         password: "password",
                         imapServerName: server,
                         imapServerPort: 993,
                         smtpServerName: server,
                         smtpServerPort: 465)
    }

    /// Temporary test function for adding MDM account data.
    private static func predeployAccount(userName: String,
                                         userAddress: String,
                                         loginName: String,
                                         password: String,
                                         imapServerName: String,
                                         imapServerPort: Int,
                                         smtpServerName: String,
                                         smtpServerPort: Int) {
        let imapServerDict = serverDictionary(name: imapServerName, port: UInt16(imapServerPort))
        let smtpServerDict = serverDictionary(name: smtpServerName, port: UInt16(smtpServerPort))
        let predeployedAccount = accountDictionary(userName: userName,
                                                   userAddress: userAddress,
                                                   loginName: loginName,
                                                   password: password,
                                                   imapServer: imapServerDict,
                                                   smtpServer: smtpServerDict)

        let predeployedAccounts: SettingsDict = [MDMPredeployed.keyPredeployedAccounts:[predeployedAccount]]
        UserDefaults.standard.set(predeployedAccounts, forKey: MDMPredeployed.keyMDM)
    }

    private static func serverDictionary(name: String, port: UInt16) -> SettingsDict {
        return [MDMPredeployed.keyServerName: name,
                MDMPredeployed.keyServerPort: NSNumber(value: port)]
    }

    private static func accountDictionary(userName: String,
                                  userAddress: String,
                                  loginName: String,
                                  password: String,
                                  imapServer: SettingsDict,
                                  smtpServer: SettingsDict) -> SettingsDict {
        return [MDMPredeployed.keyUserName: userName,
                MDMPredeployed.keyUserAddress: userAddress,
                MDMPredeployed.keyLoginName: loginName,
                MDMPredeployed.keyPassword: password,
                MDMPredeployed.keyImapServer: imapServer,
                MDMPredeployed.keySmtpServer: smtpServer]
    }
}
