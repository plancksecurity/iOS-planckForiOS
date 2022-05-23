//
//  MDMPredeployedTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 19.05.22.
//  Copyright © 2022 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel
import pEp4iosIntern

typealias SettingsDict = [String:Any]

class MDMPredeployedTest: XCTestCase {

    override func setUpWithError() throws {
        UserDefaults().removePersistentDomain(forName: kAppGroupIdentifier)
    }

    override func tearDownWithError() throws {
        Stack.shared.reset()
    }

    func testSingleAccount() throws {
        setupSinglePredepolyAccount()

        try MDMPredeployed().predeployAccounts()

        let accounts = Account.all()
        XCTAssertEqual(accounts.count, 1)

        guard let account1 = accounts.first else {
            // The number of accounts has already been checked
            return
        }

        XCTAssertEqual(account1.imapServer?.address, accountDataImapServer + "0")
        XCTAssertEqual(account1.smtpServer?.address, accountDataSmtpServer + "0")
        XCTAssertEqual(account1.imapServer?.port, accountDataImapPort)
        XCTAssertEqual(account1.smtpServer?.port, accountDataSmtpPort)
        XCTAssertEqual(account1.user.userName, accountDataUserName + "0")
        XCTAssertEqual(account1.imapServer?.credentials.loginName, accountDataLoginName + "0")
        XCTAssertEqual(account1.smtpServer?.credentials.loginName, accountDataLoginName + "0")
        XCTAssertEqual(account1.imapServer?.credentials.password, accountDataPassword + "0")
        XCTAssertEqual(account1.smtpServer?.credentials.password, accountDataPassword + "0")
    }

    func testMoreThanOneAccount() throws {
        let numAccounts = 2

        setupPredeployAccounts(number: numAccounts)

        try MDMPredeployed().predeployAccounts()

        let accounts = Account.all()
        XCTAssertEqual(accounts.count, numAccounts)

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

    func testAllExistingAccountsHaveBeenWiped() throws {
        let _ = createAccount(baseName: "acc1", portBase: 555, index: 1)
        let _ = createAccount(baseName: "acc2", portBase: 556, index: 2)

        setupSinglePredepolyAccount()

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

    // MARK: - Util

    let accountDataImapServer = "imap"
    let accountDataSmtpServer = "smtp"
    let accountDataImapPort: UInt16 = 333
    let accountDataSmtpPort: UInt16 = 444
    let accountDataUserName = "userName"
    let accountDataLoginName = "loginName"
    let accountDataPassword = "password"

    func setupPredeployAccounts(number: Int) {
        var accountDicts = [SettingsDict]()

        for i in 1...number {
            let accDict = accountWithServerDictionary(appendixNumber: i)
            accountDicts.append(accDict)
        }

        let predeployedAccounts: SettingsDict = [MDMPredeployed.keyPredeployedAccounts:accountDicts]
        let mdm: SettingsDict = [MDMPredeployed.keyMDM: predeployedAccounts]

        UserDefaults.standard.register(defaults: mdm)
    }

    func setupSinglePredepolyAccount(appendixNumber: Int = 0) {
        let accountDict = accountWithServerDictionary(appendixNumber: appendixNumber)
        let predeployedAccounts: SettingsDict = [MDMPredeployed.keyPredeployedAccounts:[accountDict]]
        let mdm: SettingsDict = [MDMPredeployed.keyMDM: predeployedAccounts]

        UserDefaults.standard.register(defaults: mdm)
    }

    func createAccount(baseName: String, portBase: Int, index: Int) -> Account {
        let session = Session.main
        let id = Identity.init(address: "\(baseName)\(index)@example.com",
                               userID: "\(baseName)\(index)",
                               addressBookID: nil,
                               userName: "\(baseName)\(index)",
                               session: session)
        let creds = ServerCredentials.init(loginName: "\(baseName)\(index)", clientCertificate: nil)
        creds.password = "password_\(portBase)\(index)"

        let imap = Server.create(serverType: .imap,
                                 port: UInt16(portBase),
                                 address: "imap\(baseName)\(portBase)\(index)",
                                 transport: .tls,
                                 credentials: creds)
        let smtp = Server.create(serverType: .smtp,
                                 port: UInt16(portBase + 1),
                                 address: "smtp\(baseName)\(portBase + 1)\(index)",
                                 transport: .tls,
                                 credentials: creds)
        let acc = Account.init(user: id, servers: [imap, smtp], session: session)
        session.commit()

        return acc
    }

    // MARK: - Util Util

    func accountWithServerDictionary(appendixNumber: Int = 0) -> SettingsDict {
        let appendix16 = UInt16(appendixNumber)
        let appendixString = "\(appendixNumber)"

        let imapServer = serverDictionary(name: accountDataImapServer + appendixString,
                                          port: accountDataImapPort + appendix16)
        let smtpServer = serverDictionary(name: accountDataSmtpServer + appendixString,
                                          port: accountDataSmtpPort + appendix16)
        let accountDict = accountDictionary(userName: accountDataUserName + appendixString,
                                            userAddress: accountDataUserName + appendixString +
                                            "@example.com",
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
