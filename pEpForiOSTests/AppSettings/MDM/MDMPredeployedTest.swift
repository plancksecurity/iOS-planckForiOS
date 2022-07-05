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
    override func setUpWithError() throws {
        setupAccountData = []
    }

    override func tearDownWithError() throws {
        Stack.shared.reset()
        XCTAssertTrue(PEPUtils.pEpClean())
        try super.tearDownWithError()
    }

    func testSingleAccountNetworkError() throws {
        XCTAssertFalse(MDMPredeployed().haveAccountsToPredeploy)
        setupSingleFailingPredeployedAccount()
        XCTAssertTrue(MDMPredeployed().haveAccountsToPredeploy)

        do {
            try predeployAccounts()
            XCTFail()
        } catch MDMPredeployedError.networkError {
        } catch {
            XCTFail()
        }

        XCTAssertFalse(MDMPredeployed().haveAccountsToPredeploy)

        let accounts = Account.all()
        XCTAssertEqual(accounts.count, 0)
    }

    func testAllExistingAccountsHaveBeenWipedAfterNetworkFail() throws {
        let _ = createAccount(baseName: "acc1", portBase: 555, index: 1)
        let _ = createAccount(baseName: "acc2", portBase: 556, index: 2)

        XCTAssertFalse(MDMPredeployed().haveAccountsToPredeploy)
        setupSingleFailingPredeployedAccount()
        XCTAssertTrue(MDMPredeployed().haveAccountsToPredeploy)

        do {
            try predeployAccounts()
            XCTFail()
        } catch MDMPredeployedError.networkError {
        } catch {
            XCTFail()
        }

        XCTAssertFalse(MDMPredeployed().haveAccountsToPredeploy)

        let accounts = Account.all()
        XCTAssertEqual(accounts.count, 0)
    }

    // MARK: - Util

    /// Wrapper around `MDMPredeployed.predeployAccounts` that makes it
    /// a sync method throwing exceptions, easier for tests to use.
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
        wait(for: [expDeployed], timeout: TestUtil.waitTime)

        if let error = potentialError {
            throw error
        }
    }

    // MARK: - Setup Util

    /// Contains account data for double-checking what has been set up.
    struct AccountStruct {
        let userAddress: String
        let imapServer: String
        let imapPort: UInt16
        let smtpServer: String
        let smtpPort: UInt16
        let userName: String
        let loginName: String
        let password: String
    }

    /// An array of all accounts that are expected to be set up
    var setupAccountData = [AccountStruct]()

    func setupFailingPredeployAccounts(number: Int) {
        var accountDicts = [SettingsDict]()

        for i in 0...number-1 {
            let accDict = failingAccountWithServerDictionary(appendixNumber: i)
            accountDicts.append(accDict)
        }

        let predeployedAccounts: SettingsDict = [MDMPredeployed.keyPredeployedAccounts:accountDicts]
        UserDefaults.standard.set(predeployedAccounts, forKey: MDMPredeployed.keyMDM)
    }

    func setupSingleFailingPredeployedAccount(appendixNumber: Int = 0) {
        let accountDict = failingAccountWithServerDictionary(appendixNumber: appendixNumber)
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

    private func failingAccountWithServerDictionary(appendixNumber: Int = 0) -> SettingsDict {
        let accountData = AccountStruct(userAddress: "account\(appendixNumber)@example.com",
                                        imapServer: "imapServer\(appendixNumber)",
                                        imapPort: 993,
                                        smtpServer: "smtpServer\(appendixNumber)",
                                        smtpPort: 587,
                                        userName: "userName\(appendixNumber)",
                                        loginName: "loginName\(appendixNumber)",
                                        password: "password\(appendixNumber)")
        if setupAccountData.count > appendixNumber {
            XCTFail()
            return [:]
        }
        setupAccountData.append(accountData)

        let imapServer = serverDictionary(name: accountData.imapServer,
                                          port: accountData.imapPort)
        let smtpServer = serverDictionary(name: accountData.smtpServer,
                                          port: accountData.smtpPort)
        let accountDict = accountDictionary(userName: accountData.userName,
                                            userAddress: accountData.userAddress,
                                            loginName: accountData.loginName,
                                            password: accountData.password,
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
