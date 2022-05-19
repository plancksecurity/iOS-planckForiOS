//
//  MDMPredeployedTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import XCTest

import pEpForiOS
import pEp4iosIntern

typealias SettingsDict = [String:Any]

class MDMPredeployedTest: XCTestCase {

    override func setUpWithError() throws {
        UserDefaults().removePersistentDomain(forName: kAppGroupIdentifier)
    }

    override func tearDownWithError() throws {
    }

    func testSingleAccount() throws {
        setupSingleAccount()
    }

    // MARK: - Util

    let keyMDM = "mdm"
    let keyPredeployedAccounts = "predeployedAccounts"
    let keyServerName = "name"
    let keyServerPort = "port"
    let keyUserName = "userName"
    let keyLoginName = "loginName"
    let keyPassword = "password"
    let keyImapServer = "imapServer"
    let keySmtpServer = "smtpServer"

    func setupSingleAccount() {
        let imapServer = serverDictionary(name: "imap", port: 333)
        let smtpServer = serverDictionary(name: "smtp", port: 444)
        let accountDict = accountDictionary(userName: "user",
                                            loginName: "login",
                                            password: "password",
                                            imapServer: imapServer,
                                            smtpServer: smtpServer)

        let predeployedAccounts: SettingsDict = [keyPredeployedAccounts:[accountDict]]
        let mdm: SettingsDict = [keyMDM: predeployedAccounts]

        UserDefaults.standard.register(defaults: mdm)
    }

    func serverDictionary(name: String, port: UInt16) -> SettingsDict {
        return [keyServerName: name, keyServerPort: NSNumber(value: port)]
    }

    func accountDictionary(userName: String,
                           loginName: String,
                           password: String,
                           imapServer: SettingsDict,
                           smtpServer: SettingsDict) -> SettingsDict {
        return [keyUserName: userName,
               keyLoginName: loginName,
                keyPassword: password,
              keyImapServer: imapServer,
              keySmtpServer: smtpServer]
    }
}
