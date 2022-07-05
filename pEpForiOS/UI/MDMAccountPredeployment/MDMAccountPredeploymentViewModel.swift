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
    enum Result: Equatable {
        /// An error ocurred during the pre-deployment
        case error(message: String)

        /// The pre-deployment succeeded
        case success(message: String)
    }

    /// Checks for predeployed accounts, and acts on them.
    func predeployAccounts(predeployer: MDMPredeployedProtocol = MDMPredeployed(),
                           callback: @escaping (_ result: Result) -> ()) {
        predeployer.predeployAccounts { maybeError in
            if let error = maybeError {
                var message: String
                switch error {
                case .networkError:
                    message = NSLocalizedString("MDM Error: Could not connect to account",
                                                comment: "MDM predeployment error")
                case .malformedAccountData:
                    message = NSLocalizedString("MDM Error: Wrong Account Data",
                                                comment: "MDM predeployment error")
                }

                callback(.error(message: message))
            } else {
                let message = NSLocalizedString("Accounts Deployed",
                                                comment: "MDM predeployment message, all ok")

                callback(.success(message: message))
            }
        }
    }
}

// MARK: - TMP Testing

private typealias SettingsDict = [String:Any]

extension MDMAccountPredeploymentViewModel {
    static func addTestData() {
        let testData = SecretTestData().createVerifiableAccountSettings(number: 0)

        predeployAccount(userName: testData.idUserName!,
                         userAddress: testData.idAddress,
                         loginName: testData.imapLoginName ?? testData.idAddress,
                         password: testData.imapPassword!,
                         imapServerName: testData.imapServerAddress,
                         imapServerPort: Int(testData.imapServerPort),
                         smtpServerName: testData.smtpServerAddress,
                         smtpServerPort: Int(testData.smtpServerPort))
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
