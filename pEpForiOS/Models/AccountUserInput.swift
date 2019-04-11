//
//  AccountUserInput.swift
//  pEpForiOS
//
//  Created by buff on 04.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PantomimeFramework

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

    /**
     Currently, the only use case for this is .saslXoauth2. In all other cases,
     this should be nil.
     */
    public let authMethod: AuthMethod?

    public var password: String?

    /**
     If the user chose OAuth2, this is the token. `password` then should be nil.
     */
    var accessToken: OAuth2AccessTokenProtocol?

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
            return pass.count > 0
        }
        return false
    }

    public var isValidName: Bool {
        return (userName?.count ?? 0) >= 1
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
                                        comment: "Alert message for empty e-mail address field")
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

        let identity = Identity(address: address, userID: nil, userName: userName, isMySelf: true)

        var logIn = self.loginName ?? address
        if logIn.isEmpty {
            logIn = address
        }

        let thePassword = accessToken?.persistBase64Encoded() ?? password
        // The key is created upfront, in case of SASL XOAUTH2, where we want to link
        // the token to the same key
        let credentialsImap = ServerCredentials.create(loginName: logIn,
                                                       key: accessToken?.keyChainID)
        credentialsImap.password = thePassword

        let imapServer = Server.create(serverType: .imap, port: self.portIMAP, address: serverIMAP,
                                       transport: self.transportIMAP.toServerTransport(),
                                       authMethod: authMethod?.rawValue,
                                       credentials: credentialsImap)

        let credentialsSmtp: ServerCredentials
        if authMethod == .saslXoauth2 {
            // In case of SASL XOAUTH2, there will be only 1 credential, with our created key
            credentialsSmtp = credentialsImap
        } else {
            credentialsSmtp = ServerCredentials.create(loginName: logIn, key: accessToken?.keyChainID)
            credentialsSmtp.password = thePassword
        }

        let smtpServer = Server.create(serverType: .smtp,
                                       port: self.portSMTP,
                                       address: serverSMTP,
                                       transport: self.transportSMTP.toServerTransport(),
                                       authMethod: authMethod?.rawValue,
                                       credentials: credentialsSmtp)

        let account = Account(user: identity, servers: [imapServer, smtpServer])
        return account
    }
}

extension AccountUserInput {
    init() {
        self.address = nil
        self.userName = nil
        self.loginName = nil
        self.authMethod = nil
        self.password = nil
        self.serverIMAP = nil
        self.serverSMTP = nil
    }
}
