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
        var smtpServerAddress: String?
        var smtpServerType: Server.ServerType = .smtp
        var smtpServerTransport: Server.Transport = .tls
        var smtpServerPort: UInt16 = 587
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
             imapServerAddress: String,
             imapServerType: Server.ServerType,
             imapServerTransport: Server.Transport,
             imapServerPort: UInt16,
             smtpServerAddress: String,
             smtpServerType: Server.ServerType,
             smtpServerTransport: Server.Transport,
             smtpServerPort: UInt16,
             password: String) {
            self.accountName = accountName
            self.idAddress = idAddress
            self.idUserName = idUserName
            self.smtpServerAddress = smtpServerAddress
            self.smtpServerType = smtpServerType
            self.smtpServerTransport = smtpServerTransport
            self.smtpServerPort = smtpServerPort
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

            let smtp = CdServer.create()
            smtp.serverType = smtpServerType
            smtp.port = NSNumber(value: smtpServerPort)
            smtp.address = smtpServerAddress
            smtp.transport = smtpServerTransport

            let imap = CdServer.create()
            imap.serverType = imapServerType
            imap.port = NSNumber(value: imapServerPort)
            imap.address = imapServerAddress
            imap.transport = imapServerTransport

            let key = MessageID.generate()
            CdServerCredentials.add(password: password, forKey: key)

            let cred = CdServerCredentials.create()
            cred.userName = id.address
            cred.key = key
            cred.servers = NSSet(array: [imap, smtp])

            let acc = CdAccount.create()
            acc.identity = id
            acc.credentials = NSOrderedSet(array: [cred])

            return acc
        }

        func account() -> Account {
            let id = Identity.create(address: idAddress, userName: idUserName, isMySelf: true)

            let smtp = Server.create(serverType: .smtp,
                                     port: smtpServerPort,
                                     address: smtpServerAddress ?? "",
                                     transport: smtpServerTransport)

            let imap = Server.create(serverType: .imap,
                                     port: imapServerPort,
                                     address: imapServerAddress ?? "",
                                     transport: imapServerTransport)

            // Assumes
            let cred = ServerCredentials.create(userName: id.address,
                                                password: password,
                                                servers: [smtp, imap])

            let acc = Account.create(identity: id, credentials: [cred])

            return acc
        }

        func pEpIdentity() -> [String: AnyObject] {
            let theID = [
                kPepAddress: idAddress as AnyObject,
                kPepUsername: accountName as AnyObject
                ] as [String: AnyObject]
            return theID
        }
    }

    fileprivate var testAccounts = [AccountSettings]()

    func append(accountSettings: AccountSettings) {
        testAccounts.append(accountSettings)
    }

    /**
     - Note: Add test accounts in TestData.swift only!).
     */
    func populateAccounts() {
        fatalError("Abstract method. Must be overridden")
    }

    /**
     - Returns: A valid `CdAccount`.
     */
    func createWorkingCdAccount(number: Int = 0) -> CdAccount {
        populateAccounts()
        return testAccounts[number].cdAccount()
    }

    /**
     - Returns: A `CdAccount` that should not be able to be verified.
     */
    func createDisfunctionalCdAccount() -> CdAccount {
        populateAccounts()
        var accountSettings = testAccounts[0]
        accountSettings.smtpServerAddress = "localhost"
        accountSettings.smtpServerPort = 2323
        accountSettings.imapServerPort = 2323
        accountSettings.imapServerAddress = "localhost"
        return accountSettings.cdAccount()
    }

    /**
     - Returns: A valid `Account`.
     */
    func createWorkingAccount(number: Int = 0) -> Account {
        populateAccounts()
        return testAccounts[number].account()
    }

    /**
     - Returns: A valid `PEPIdentity`.
     */
    func createWorkingIdentity(number: Int = 0) -> [String: AnyObject] {
        populateAccounts()
        return testAccounts[number].pEpIdentity()
    }

    /**
     - Returns: An `AccountSettings` object with an SMTP server that should yield a quick timeout.
     */
    func createSmtpTimeOutAccountSettings() -> AccountSettings {
        populateAccounts()
        var accountSettings = testAccounts[0]
        accountSettings.smtpServerAddress = "localhost"
        accountSettings.smtpServerPort = 2323
        return accountSettings
    }

    /**
     - Returns: An `AccountSettings` object with an IMAP server that should yield a quick timeout.
     */
    func createImapTimeOutAccountSettings() -> AccountSettings {
        populateAccounts()
        var accountSettings = testAccounts[0]
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
