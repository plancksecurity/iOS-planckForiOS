//
//  AppDelegate+PredeployedAccounts.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 24.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox

private typealias SettingsDict = [String:Any]

extension AppDelegate {
    /// Checks for predeployed accounts, and acts on them.
    public func predeployAccounts() {
        let predeployer: MDMPredeployedProtocol = MDMPredeployed()
        do {
            try predeployer.predeployAccounts()
        } catch {
            // TODO: Show the error to the user.
            Log.shared.errorAndCrash(error: error)
        }
    }

    /// Temporary test function for adding MDM account data.
    public func predeployAccount(userName: String,
                                 userAddress: String,
                                 loginName: String,
                                 password: String,
                                 imapServerName: String,
                                 imapServerPort: Int,
                                 smtpServerName: String,
                                 smtpServerPort: Int) {
        let imapServerDict = serverDictionary(name: imapServerName, port: imapServerPort)
    }

    private func serverDictionary(name: String, port: UInt16) -> SettingsDict {
        return [MDMPredeployed.keyServerName: name,
                MDMPredeployed.keyServerPort: NSNumber(value: port)]
    }

    private func accountDictionary(userName: String,
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
