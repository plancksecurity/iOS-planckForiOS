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

    func append(accountSettings: AccountSettings) {
        testAccounts.append(accountSettings)
    }

    /**
     - Note:
       * Add test accounts in TestData.swift only!).
       * The first 2 accounts play in tandem for some tests.
     */
    func populateAccounts() {
        // Some sample code, use this in your own implementation.
        append(accountSettings: AccountSettings(
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

    /**
     - Returns: A valid `Account`.
     */
    func createWorkingAccount(number: Int = 0) -> Account {
        return createWorkingAccountSettings(number: number).account()
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
        var accountSettings = createWorkingAccountSettings(number: 0)
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
