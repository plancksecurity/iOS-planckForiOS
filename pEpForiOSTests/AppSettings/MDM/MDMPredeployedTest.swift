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

        try MDMPredeployed().predeployAccounts()

        let accounts = Account.all()
        XCTAssertEqual(accounts.count, 1)

        guard let account1 = accounts.first else {
            // The number of accounts has already been checked
            return
        }

        XCTAssertEqual(account1.imapServer?.address, accountDataImapServer)
        XCTAssertEqual(account1.smtpServer?.address, accountDataSmtpServer)
        XCTAssertEqual(account1.imapServer?.port, accountDataImapPort)
        XCTAssertEqual(account1.smtpServer?.port, accountDataSmtpPort)
        XCTAssertEqual(account1.user.userName, accountDataUserName)
        XCTAssertEqual(account1.imapServer?.credentials.loginName, accountDataLoginName)
        XCTAssertEqual(account1.smtpServer?.credentials.loginName, accountDataLoginName)
        XCTAssertEqual(account1.imapServer?.credentials.password, accountDataPassword)
        XCTAssertEqual(account1.smtpServer?.credentials.password, accountDataPassword)
    }

    func testMoreThanOneAccount() throws {
        let numAccounts = 2

        setupAccounts(number: numAccounts)

        try MDMPredeployed().predeployAccounts()

        let accounts = Account.all()
        XCTAssertEqual(accounts.count, numAccounts
        )

        var optionalPrevAccount: Account? = nil
        for acc in accounts {
            if let account1 = optionalPrevAccount {
                XCTAssertNotEqual(account1.imapServer?.address, acc.imapServer?.address)
                XCTAssertNotEqual(account1.smtpServer?.address, acc.smtpServer?.address)
                XCTAssertNotEqual(account1.imapServer?.port, acc.imapServer?.port)
                XCTAssertNotEqual(account1.smtpServer?.port, acc.smtpServer?.port)
                XCTAssertNotEqual(account1.user.userName, acc.user.userName)
                XCTAssertNotEqual(account1.imapServer?.credentials.loginName,
                                  acc.imapServer?.credentials.loginName)
                XCTAssertNotEqual(account1.smtpServer?.credentials.loginName,
                                  acc.smtpServer?.credentials.loginName)
                XCTAssertNotEqual(account1.imapServer?.credentials.password,
                                  acc.imapServer?.credentials.password)
                XCTAssertNotEqual(account1.smtpServer?.credentials.password,
                                  acc.smtpServer?.credentials.password)
            }
            optionalPrevAccount = acc
        }
    }

    // MARK: - Util

    let accountDataImapServer = "imap"
    let accountDataSmtpServer = "smtp"
    let accountDataImapPort: UInt16 = 333
    let accountDataSmtpPort: UInt16 = 444
    let accountDataUserName = "userName"
    let accountDataLoginName = "loginName"
    let accountDataPassword = "password"

    func setupAccounts(number: Int) {
        var accountDicts = [SettingsDict]()

        for i in 1...number {
            let accDict = accountWithServerDictionary(appendixNumber: i)
            accountDicts.append(accDict)
        }

        let predeployedAccounts: SettingsDict = [MDMPredeployed.keyPredeployedAccounts:accountDicts]
        let mdm: SettingsDict = [MDMPredeployed.keyMDM: predeployedAccounts]

        UserDefaults.standard.register(defaults: mdm)
    }

    func setupSingleAccount(appendixNumber: Int = 0) {
        let accountDict = accountWithServerDictionary(appendixNumber: appendixNumber)
        let predeployedAccounts: SettingsDict = [MDMPredeployed.keyPredeployedAccounts:[accountDict]]
        let mdm: SettingsDict = [MDMPredeployed.keyMDM: predeployedAccounts]

        UserDefaults.standard.register(defaults: mdm)
    }

    func accountWithServerDictionary(appendixNumber: Int = 0) -> SettingsDict {
        let appendix16 = UInt16(appendixNumber)
        let appendixString = "\(appendixNumber)"

        let imapServer = serverDictionary(name: accountDataImapServer + appendixString,
                                          port: accountDataImapPort + appendix16)
        let smtpServer = serverDictionary(name: accountDataSmtpServer + appendixString,
                                          port: accountDataSmtpPort + appendix16)
        let accountDict = accountDictionary(userName: accountDataUserName + appendixString,
                                            loginName: accountDataLoginName + appendixString,
                                            password: accountDataPassword + appendixString,
                                            imapServer: imapServer,
                                            smtpServer: smtpServer)

        return accountDict
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
