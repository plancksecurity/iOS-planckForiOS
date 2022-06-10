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

private typealias SettingsDict = [String:Any]

class MDMPredeployedTest: XCTestCase {

    override func tearDownWithError() throws {
        Stack.shared.reset()
        XCTAssertTrue(PEPUtils.pEpClean())
        try super.tearDownWithError()
    }

    func testSingleAccount() throws {
        setupSinglePredeployedAccount()

        try predeployAccounts()

        let accounts = Account.all()
        XCTAssertEqual(accounts.count, 1)

        guard let account1 = accounts.first else {
            // The number of accounts has already been checked
            return
        }

        XCTAssertEqual(account1.imapServer?.address,
                       indexed(string: accountDataImapServer, index: 0))
        XCTAssertEqual(account1.smtpServer?.address,
                       indexed(string: accountDataSmtpServer, index: 0))
        XCTAssertEqual(account1.imapServer?.port, accountDataImapPort)
        XCTAssertEqual(account1.smtpServer?.port, accountDataSmtpPort)
        XCTAssertEqual(account1.user.userName,
                       indexed(string: accountDataUserName, index: 0))
        XCTAssertEqual(account1.imapServer?.credentials.loginName,
                       indexed(string: accountDataLoginName, index: 0))
        XCTAssertEqual(account1.smtpServer?.credentials.loginName,
                       indexed(string: accountDataLoginName, index: 0))
        XCTAssertEqual(account1.imapServer?.credentials.password,
                       indexed(string: accountDataPassword, index:0))
        XCTAssertEqual(account1.smtpServer?.credentials.password,
                       indexed(string: accountDataPassword, index: 0))
    }

    func testMoreThanOneAccount() throws {
        let numAccounts = 2

        setupPredeployAccounts(number: numAccounts)

        try predeployAccounts()

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

        setupSinglePredeployedAccount()

        try predeployAccounts()

        let accounts = Account.all()
        XCTAssertEqual(accounts.count, 1)

        guard let account1 = accounts.first else {
            // The number of accounts has already been checked
            return
        }

        XCTAssertEqual(account1.imapServer?.address,
                       indexed(string: accountDataImapServer, index: 0))
        XCTAssertEqual(account1.smtpServer?.address,
                       indexed(string: accountDataSmtpServer, index: 0))
        XCTAssertEqual(account1.imapServer?.port, accountDataImapPort)
        XCTAssertEqual(account1.smtpServer?.port, accountDataSmtpPort)
        XCTAssertEqual(account1.user.userName,
                       indexed(string: accountDataUserName, index: 0))
        XCTAssertEqual(account1.imapServer?.credentials.loginName,
                       indexed(string: accountDataLoginName, index: 0))
        XCTAssertEqual(account1.smtpServer?.credentials.loginName,
                       indexed(string: accountDataLoginName, index: 0))
        XCTAssertEqual(account1.imapServer?.credentials.password,
                       indexed(string: accountDataPassword, index:0))
        XCTAssertEqual(account1.smtpServer?.credentials.password,
                       indexed(string: accountDataPassword, index:0))
    }

    // MARK: - Util

    /// Wrapper around `MDMPredeployed.predeployAccounts` that makes it
    /// sync and using exceptions, easier for tests to use.
    func predeployAccounts() throws {
        var potentialError: Error?

        let expDeployed = expectation(description: "expDeployed")
        MDMPredeployed().predeployAccounts { maybeError in
            expDeployed.fulfill()
            if let error = maybeError {
                potentialError = error
            } else {
                // After successful deploy, there should not be any accounts to predeploy anymore
                if let mdmDictCheck = UserDefaults.standard.dictionary(forKey: MDMPredeployed.keyMDM) {
                    XCTAssertNil(mdmDictCheck[MDMPredeployed.keyPredeployedAccounts])
                }
            }
        }
        wait(for: [expDeployed], timeout: TestUtil.waitTimeLocal)

        if let error = potentialError {
            throw error
        }
    }

    // MARK: - Setup Util

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
        UserDefaults.standard.set(predeployedAccounts, forKey: MDMPredeployed.keyMDM)
    }

    func setupSinglePredeployedAccount(appendixNumber: Int = 0) {
        let accountDict = accountWithServerDictionary(appendixNumber: appendixNumber)
        let predeployedAccounts: SettingsDict = [MDMPredeployed.keyPredeployedAccounts:[accountDict]]
        UserDefaults.standard.set(predeployedAccounts, forKey: MDMPredeployed.keyMDM)
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

    func indexed(string: String, index: Int) -> String {
        return "\(string)\(index)"
    }

    // MARK: - Setup Util Util

    private func accountWithServerDictionary(appendixNumber: Int = 0) -> SettingsDict {
        let appendix16 = UInt16(appendixNumber)

        let imapServer = serverDictionary(name: indexed(string: accountDataImapServer,
                                                        index: appendixNumber),
                                          port: accountDataImapPort + appendix16)
        let smtpServer = serverDictionary(name: indexed(string: accountDataSmtpServer,
                                                        index: appendixNumber),
                                          port: accountDataSmtpPort + appendix16)
        let accountDict = accountDictionary(userName: indexed(string: accountDataUserName,
                                                              index: appendixNumber),
                                            userAddress: indexed(string: accountDataUserName,
                                                                 index: appendixNumber) +
                                            "@example.com",
                                            loginName: indexed(string: accountDataLoginName,
                                                               index: appendixNumber),
                                            password: indexed(string: accountDataPassword,
                                                              index: appendixNumber),
                                            imapServer: imapServer,
                                            smtpServer: smtpServer)

        return accountDict
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
