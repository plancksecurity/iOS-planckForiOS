//
//  MDMAccountPredeploymentViewModel.swift
//  pEp
//
//  Created by Dirk Zimmermann on 30.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

protocol MDMAccountPredeploymentViewModelDelegate: NSObject {
}

class MDMAccountPredeploymentViewModel {
    weak var delegate: MDMAccountPredeploymentViewModelDelegate?

    /// Checks for predeployed accounts, and acts on them.
    ///
    /// - Note: Silently fails if there was an error is the account description.
    func predeployAccounts() {
        if !AppSettings.shared.mdmPredeployAccounts {
            return
        }

        let predeployer: MDMPredeployedProtocol = MDMPredeployed()
        do {
            try predeployer.predeployAccounts()
        } catch {
            Log.shared.logError(message: "Error during MDM account predeployment: \(error)")
            return
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

        let mdm: SettingsDict = [MDMPredeployed.keyMDM: [predeployedAccount]]

        UserDefaults.standard.register(defaults: mdm)
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
