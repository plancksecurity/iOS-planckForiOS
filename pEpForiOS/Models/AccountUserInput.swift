//
//  AccountUserInput.swift
//  pEpForiOS
//
//  Created by buff on 04.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

public struct AccountUserInput {
    public var email: String?
    /**
     The actual name of the user, or nick name.
     */
    public var name: String?
    /**
     An optional name for the servers, if needed.
     */
    public var username: String?
    public var password: String?
    public var serverIMAP: String?
    public var portIMAP: UInt16 = 993
    public var transportIMAP = ConnectionTransport.TLS
    public var serverSMTP: String?
    public var portSMTP: UInt16 = 587
    public var transportSMTP = ConnectionTransport.startTLS

    public var isValidEmail: Bool {
        if let em = email {
            return em.isProbablyValidEmail()
        }
        return false
    }

    public var isValidPassword: Bool {
        if let pass = password {
            return pass.characters.count > 0
        }
        return false
    }

    public var isValidName: Bool {
        return (name?.characters.count ?? 0) >= 3
    }

    public var isValidUser: Bool {
        return isValidName && isValidEmail && isValidPassword
    }

    public var isValidImap: Bool {
        return false
    }

    public var isValidSmtp: Bool {
        return false
    }

    /// Returns an Account instance filled with data of self.
    /// It does not deal with Core Data (does not persist).
    /// Only data from this model is taken into account, not needsVerivication or others.
    ///
    /// - Returns: filled Account
    /// - Throws: AccountSettingsUserInputError
    public func account() throws -> Account {
        guard let address = self.email, address != "" else {
            let msg = NSLocalizedString("E-mail must not be empty",
                                        comment: "Alert message for empty em-mail address field")
            throw AccountSettingsUserInputError.invalidInputEmailAddress(localizedMessage: msg)
        }
        guard let name = self.name, name != "" else { //BUFF: assure name is account name (first field in first view)
            let msg = NSLocalizedString("Account name must not be empty",
                                        comment: "Alert message for empty account name")
            throw AccountSettingsUserInputError.invalidInputAccountName(localizedMessage: msg)
        }
        guard let loginUser = self.username, loginUser != "" else {
            let msg = NSLocalizedString("Username must not be empty",
                                        comment: "Alert message for empty username")
            throw AccountSettingsUserInputError.invalidInputUserName(localizedMessage: msg)
        }
        guard let serverIMAP = self.serverIMAP, serverIMAP != "" else {
            let msg = NSLocalizedString("IMAP server must not be empty",
                                        comment: "Alert message for empty IMAP server")
            throw AccountSettingsUserInputError.invalidInputServer(localizedMessage: msg)
        }
        guard let serverSMTP = self.serverSMTP, serverSMTP != "" else {
            let msg = NSLocalizedString("SMTP server must not be empty",
                                        comment: "Alert message for empty SMTP server")
            throw AccountSettingsUserInputError.invalidInputServer(localizedMessage: msg)
        }

        let identity = Identity.create(address: address, userID: nil, userName: name,
                                       isMySelf: true)

        let credentials = ServerCredentials.create(userName: loginUser, password: self.password)
        credentials.needsVerification = true

        let imapServer = Server.create(serverType: .imap, port: self.portIMAP, address: serverIMAP,
                                       transport: self.transportIMAP.toServerTransport(),
                                       credentials: credentials)
        imapServer.needsVerification = true

        let smtpServer = Server.create(serverType: .smtp, port: self.portSMTP, address: serverSMTP,
                                       transport: self.transportSMTP.toServerTransport(),
                                       credentials: credentials)
        smtpServer.needsVerification = true

        let servers = [imapServer, smtpServer]
        let account = Account.create(identity: identity, servers: servers)

        return account
    }
}
