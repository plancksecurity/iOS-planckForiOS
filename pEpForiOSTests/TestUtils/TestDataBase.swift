//
//  TestData.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 02/11/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import UIKit
import CoreData

import MessageModel
import PEPObjCAdapterFramework

class TestDataBase {
    struct AccountSettings {
        var accountName: String?
        var idAddress: String
        var idUserName: String?
        var smtpLoginName: String?
        var smtpServerAddress: String?
        var smtpServerType: Server.ServerType = .smtp
        var smtpServerTransport: Server.Transport = .tls
        var smtpServerPort: UInt16 = 587
        var imapLoginName: String?
        var imapServerAddress: String?
        var imapServerType: Server.ServerType = .imap
        var imapServerTransport: Server.Transport = .startTls
        var imapServerPort: UInt16 = 993
        var password: String?

        init(accountName: String?, address: String) {
            self.accountName = accountName
            self.idAddress = address
        }

        init(address: String) {
            self.init(accountName: nil, address: address)
        }

        init(accountName: String,
             idAddress: String,
             idUserName: String,
             imapLoginName: String? = nil,
             imapServerAddress: String,
             imapServerType: Server.ServerType,
             imapServerTransport: Server.Transport,
             imapServerPort: UInt16,
             smtpLoginName: String? = nil,
             smtpServerAddress: String,
             smtpServerType: Server.ServerType,
             smtpServerTransport: Server.Transport,
             smtpServerPort: UInt16,
             password: String) {
            self.accountName = accountName
            self.idAddress = idAddress
            self.idUserName = idUserName
            self.smtpLoginName = smtpLoginName
            self.smtpServerAddress = smtpServerAddress
            self.smtpServerType = smtpServerType
            self.smtpServerTransport = smtpServerTransport
            self.smtpServerPort = smtpServerPort
            self.imapLoginName = imapLoginName
            self.imapServerAddress = imapServerAddress
            self.imapServerType = imapServerType
            self.imapServerTransport = imapServerTransport
            self.imapServerPort = imapServerPort
            self.password = password
        }

        func cdAccount() -> CdAccount {
            let id = CdIdentity.create()
            id.address = idAddress
            id.userName = idUserName
            id.userID = CdIdentity.pEpOwnUserID

            let acc = CdAccount.create()
            acc.identity = id

            //SMTP
            let smtp = CdServer.create()
            smtp.serverType = smtpServerType
            smtp.port = NSNumber(value: smtpServerPort)
            smtp.address = smtpServerAddress
            smtp.transport = smtpServerTransport

            let keySmtp = MessageID.generate()
            CdServerCredentials.add(password: password, forKey: keySmtp)
            let credSmtp = CdServerCredentials.create()
            credSmtp.loginName = smtpLoginName ?? id.address
            credSmtp.key = keySmtp
            smtp.credentials = credSmtp

            acc.addToServers(smtp)

            //IMAP
            let imap = CdServer.create()
            imap.serverType = imapServerType
            imap.port = NSNumber(value: imapServerPort)
            imap.address = imapServerAddress
            imap.transport = imapServerTransport

            let keyImap = MessageID.generate()
            CdServerCredentials.add(password: password, forKey: keyImap)
            let credImap = CdServerCredentials.create()
            credImap.loginName = imapLoginName ?? id.address
            credImap.key = keyImap
            imap.credentials = credImap

            acc.addToServers(imap)

            return acc
        }

        func cdIdentityWithoutAccount(isMyself: Bool = false) -> CdIdentity {
            let id = CdIdentity.create()
            id.address = idAddress
            id.userName = idUserName
            if isMyself {
                id.userID = CdIdentity.pEpOwnUserID
            } else {
                id.userID = UUID().uuidString
            }
            return id
        }

        func account() -> Account {
            let id = Identity.create(address: idAddress, userName: idUserName, isMySelf: true)

            let credSmtp = ServerCredentials.create(loginName: id.address)
            credSmtp.password = password
            let smtp = Server.create(serverType: .smtp,
                                     port: smtpServerPort,
                                     address: smtpServerAddress ?? "",
                                     transport: smtpServerTransport,
                                     credentials:credSmtp)

            let credImap = ServerCredentials.create(loginName: id.address)
            credImap.password = password
            let imap = Server.create(serverType: .imap,
                                     port: imapServerPort,
                                     address: imapServerAddress ?? "",
                                     transport: imapServerTransport,
                                     credentials:credImap)
            
            let acc = Account(user: id, servers: [smtp, imap])

            return acc
        }

        func pEpIdentity() -> PEPIdentity {
            let ident = PEPIdentity(address: idAddress)
            ident.userName = accountName
            return ident
        }
    }

    private var testAccounts = [AccountSettings]()
    private var verifiableTestAccounts = [AccountSettings]()

    func append(accountSettings: AccountSettings) {
        testAccounts.append(accountSettings)
    }

    func append(verifiableAccountSettings: AccountSettings) {
        verifiableTestAccounts.append(verifiableAccountSettings)
    }

    /**
     Add IMAP/SMTP accounts that are used for testing.
     - Note:
       * These (local) accounts depend on a local greenmail server.
         Please see the readme for details.
       * Override this in SecretTestData if needed, for testing external servers.
       * The first 2 accounts play in tandem for some tests.
       * Some tests send emails to unittest.ios.1@peptest.ch,
         this account has to exist but there's no need to query it.
     */
    func populateAccounts() {
        addLocalTestAccount(userName: "test001")
        addLocalTestAccount(userName: "test002")
        addLocalTestAccount(userName: "test003")
    }

    private func addLocalTestAccount(userName: String) {
        let address = "\(userName)@localhost"
        append(accountSettings: AccountSettings(
            accountName: "Unit Test \(address)",
            idAddress: address,
            idUserName: "User \(address)",

            imapLoginName: userName,
            imapServerAddress: "localhost",
            imapServerType: Server.ServerType.imap,
            imapServerTransport: Server.Transport.plain,
            imapServerPort: 3143,

            smtpLoginName: userName,
            smtpServerAddress: "localhost",
            smtpServerType: Server.ServerType.smtp,
            smtpServerTransport: Server.Transport.plain,
            smtpServerPort: 3025,

            password: "pwd"))
    }

    /**
     Accounts needed for testing LAS, that is they need to be registered
     in the LAS DB or provide (correct) DNS SRV for IMAP and SMTP.
     */
    func populateVerifiableAccounts() {
        append(verifiableAccountSettings: AccountSettings(
            accountName: "Whatever_you_want",
            idAddress: "whatever_you_want@yahoo.com",
            idUserName: "whatever_you_want@yahoo.com",

            imapServerAddress: "imap.mail.yahoo.com",
            imapServerType: Server.ServerType.imap,
            imapServerTransport: Server.Transport.tls,
            imapServerPort: 993,

            smtpServerAddress: "smtp.mail.yahoo.com",
            smtpServerType: Server.ServerType.smtp,
            smtpServerTransport: Server.Transport.tls,
            smtpServerPort: 465,

            password: "whatever_you_want"))

        fatalError("Abstract method. Must be overridden")
    }

    /**
     - Returns: A valid `CdAccount`.
     */
    func createWorkingCdAccount(number: Int = 0) -> CdAccount {
        let result = createWorkingAccountSettings(number: number).cdAccount()
        // The identity of an account is mySelf by definion.
        result.identity?.userID = CdIdentity.pEpOwnUserID
        return result
    }

    /**
     - Returns: A valid `CdAccount`.
     */
    func createVerifiableCdAccount(number: Int = 0) -> CdAccount {
        let result = createVerifiableAccountSettings(number: number).cdAccount()
        // The identity of an account is mySelf by definion.
        result.identity?.userID = CdIdentity.pEpOwnUserID
        return result
    }

    /**
     - Returns: A valid `CdIdentity` without parent account.
     */
    func createWorkingCdIdentity(number: Int = 0, isMyself: Bool = false) -> CdIdentity {
        let result = createWorkingAccountSettings(number: number).cdIdentityWithoutAccount(isMyself: isMyself)
        return result
    }

    /**
     - Returns: A `CdAccount` that should not be able to be verified.
     */
    func createDisfunctionalCdAccount() -> CdAccount {
        var accountSettings = createWorkingAccountSettings(number: 0)
        accountSettings.smtpServerAddress = "localhost"
        accountSettings.smtpServerPort = 2323
        accountSettings.imapServerPort = 2323
        accountSettings.imapServerAddress = "localhost"
        return accountSettings.cdAccount()
    }

    func createWorkingAccountSettings(number: Int = 0) -> AccountSettings {
        populateAccounts()
        return testAccounts[number]
    }

    func createVerifiableAccountSettings(number: Int = 0) -> AccountSettings {
        populateVerifiableAccounts()
        return verifiableTestAccounts[number]
    }

    /**
     - Returns: A valid `Account`.
     */
    func createWorkingAccount(number: Int = 0) -> Account {
        return createWorkingAccountSettings(number: number).account()
    }

    /**
     - Returns: A valid `Account`.
     */
    func createVerifiableAccount(number: Int = 0) -> Account {
        return createVerifiableAccountSettings(number: number).account()
    }

    /**
     - Returns: A valid `PEPIdentity`.
     */
    func createWorkingIdentity(number: Int = 0, isMyself: Bool = false) -> PEPIdentity {
        populateAccounts()
        return createWorkingCdIdentity(number: number, isMyself: isMyself).pEpIdentity()
    }

    /**
     - Returns: An `AccountSettings` object with an SMTP server that should yield a quick timeout.
     */
    func createSmtpTimeOutAccountSettings() -> AccountSettings {
        populateAccounts()
        var accountSettings = createVerifiableAccountSettings(number: 0)
        accountSettings.smtpServerAddress = "localhost"
        accountSettings.smtpServerPort = 2323
        return accountSettings
    }

    /**
     - Returns: An `AccountSettings` object with an IMAP server that should yield a quick timeout.
     */
    func createImapTimeOutAccountSettings() -> AccountSettings {
        populateAccounts()
        var accountSettings = createWorkingAccountSettings(number: 0)
        accountSettings.imapServerAddress = "localhost"
        accountSettings.imapServerPort = 2323
        return accountSettings
    }

    /**
     - Returns: A `CdAccount` around `createSmtpTimeOutAccountSettings`.
     */
    func createSmtpTimeOutCdAccount() -> CdAccount {
        return createSmtpTimeOutAccountSettings().cdAccount()
    }

    /**
     - Returns: An `Account` around `createSmtpTimeOutAccountSettings`.
     */
    func createSmtpTimeOutAccount() -> Account {
        return createSmtpTimeOutAccountSettings().account()
    }

    /**
     - Returns: An `Account` around `createImapTimeOutAccountSettings`.
     */
    func createImapTimeOutAccount() -> Account {
        return createImapTimeOutAccountSettings().account()
    }

}
