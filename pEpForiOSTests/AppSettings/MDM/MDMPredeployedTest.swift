//
//  MDMPredeployedTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
import MessageModel
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
        MDMPredeployed().predeployAccounts()

        let accounts = Account.all()
        XCTAssertEqual(accounts.count, 1)

        guard let account1 = accounts.first else {
            // The number of accounts has already been checked
            return
        }

        XCTAssertEqual(account1.imapServer?.address, imapServer)
        XCTAssertEqual(account1.smtpServer?.address, smtpServer)
        XCTAssertEqual(account1.imapServer?.port, imapPort)
        XCTAssertEqual(account1.smtpServer?.port, smtpPort)
    }

    // MARK: - Util

    let imapServer = "imap"
    let smtpServer = "smtp"
    let imapPort: UInt16 = 333
    let smtpPort: UInt16 = 444

    func setupSingleAccount() {
        let imapServer = serverDictionary(name: imapServer, port: imapPort)
        let smtpServer = serverDictionary(name: smtpServer, port: smtpPort)
        let accountDict = accountDictionary(userName: "user",
                                            loginName: "login",
                                            password: "password",
                                            imapServer: imapServer,
                                            smtpServer: smtpServer)

        let predeployedAccounts: SettingsDict = [MDMPredeployed.keyPredeployedAccounts:[accountDict]]
        let mdm: SettingsDict = [MDMPredeployed.keyMDM: predeployedAccounts]

        UserDefaults.standard.register(defaults: mdm)
    }

    func serverDictionary(name: String, port: UInt16) -> SettingsDict {
        return [MDMPredeployed.keyServerName: name,
                MDMPredeployed.keyServerPort: NSNumber(value: port)]
    }

    func accountDictionary(userName: String,
                           loginName: String,
                           password: String,
                           imapServer: SettingsDict,
                           smtpServer: SettingsDict) -> SettingsDict {
        return [MDMPredeployed.keyUserName: userName,
                MDMPredeployed.keyLoginName: loginName,
                MDMPredeployed.keyPassword: password,
                MDMPredeployed.keyImapServer: imapServer,
                MDMPredeployed.keySmtpServer: smtpServer]
    }
}
