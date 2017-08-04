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
    /// - Throws: AccountVerificationError
    public func account() throws -> Account {
        guard let address = self.email, let name = self.name,
            let loginUser = self.username, let serverIMAP = self.serverIMAP,
            let serverSMTP = self.serverSMTP else {
                throw AccountVerificationError.insufficientInput
        }

        let identity = Identity.create(address: address, userID: address, userName: name,
                                       isMySelf: true, toPersist: false) //BUFF: remove persist stuff. Everywhere! //make create methods unreachable

        let imapServer = Server.create(serverType: .imap, port: self.portIMAP, address: serverIMAP,
                                       transport: self.transportIMAP.toServerTransport(),
                                       toPersist: false)
        imapServer.needsVerification = true

        let smtpServer = Server.create(serverType: .smtp, port: self.portSMTP, address: serverSMTP,
                                       transport: self.transportSMTP.toServerTransport(),
                                       toPersist: false)
        smtpServer.needsVerification = true

        let credentials = ServerCredentials.create(userName: loginUser, password: self.password,
                                                   servers: [imapServer, smtpServer])
        credentials.needsVerification = true
        let account = Account.create(identity: identity, credentials: [credentials],
                                     toPersist: false)
        return account
    }
}
