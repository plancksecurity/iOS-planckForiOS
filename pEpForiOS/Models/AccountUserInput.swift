//
//  AccountUserInput.swift
//  pEpForiOS
//
//  Created by buff on 04.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

public struct AccountUserInput {
    public var address: String?

    /**
     The actual name of the user, or nick name. Not to be confused with the login name.
     */
    public var userName: String?

    /**
     An optional name for the servers, if needed.
     */
    public var loginName: String?

    public var password: String?
    public var serverIMAP: String?
    public var portIMAP: UInt16 = 993
    public var transportIMAP = ConnectionTransport.TLS
    public var serverSMTP: String?
    public var portSMTP: UInt16 = 587
    public var transportSMTP = ConnectionTransport.startTLS

    public var isValidEmail: Bool {
        return address?.isProbablyValidEmail() ?? false
    }

    public var isValidPassword: Bool {
        if let pass = password {
            return pass.characters.count > 0
        }
        return false
    }

    public var isValidName: Bool {
        return (userName?.characters.count ?? 0) >= 1
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
        guard let address = self.address, address != "" else {
            let msg = NSLocalizedString("E-mail must not be empty",
                                        comment: "Alert message for empty em-mail address field")
            throw AccountSettingsUserInputError.invalidInputEmailAddress(localizedMessage: msg)
        }

        guard let userName = self.userName, userName != "" else {
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

        let identity = Identity.create(address: address, userID: nil, userName: userName,
                                       isMySelf: true)

        var logIn = self.loginName ?? address
        if logIn.isEmpty {
            logIn = address
        }

        let credentialsImap = ServerCredentials.create(loginName: logIn,
                                                       password: self.password)
        credentialsImap.needsVerification = true

        let imapServer = Server.create(serverType: .imap, port: self.portIMAP, address: serverIMAP,
                                       transport: self.transportIMAP.toServerTransport(),
                                       credentials: credentialsImap)
        imapServer.needsVerification = true

        let credentialsSmtp = ServerCredentials.create(loginName: logIn,
                                                       password: self.password)
        credentialsSmtp.needsVerification = true
        let smtpServer = Server.create(serverType: .smtp, port: self.portSMTP, address: serverSMTP,
                                       transport: self.transportSMTP.toServerTransport(),
                                       credentials: credentialsSmtp)
        smtpServer.needsVerification = true

        let account = Account(user: identity, servers: [imapServer, smtpServer])
        return account
    }
}
