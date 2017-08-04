//
//  ModelUserInfoTable.swift
//  pEpForiOS
//
//  Created by buff on 04.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel

//BUFF: make struct
open class ModelUserInfoTable {
    open var email: String?

    /**
     The actual name of the user, or nick name.
     */
    open var name: String?

    /**
     An optional name for the servers, if needed.
     */
    open var username: String?
    open var password: String?
    open var serverIMAP: String?
    open var portIMAP: UInt16 = 993
    open var transportIMAP = ConnectionTransport.TLS
    open var serverSMTP: String?
    open var portSMTP: UInt16 = 587
    open var transportSMTP = ConnectionTransport.startTLS

    open var isValidEmail: Bool {
        if let em = email {
            return em.isProbablyValidEmail()
        }
        return false
    }

    open var isValidPassword: Bool {
        if let pass = password {
            return pass.characters.count > 0
        }
        return false
    }

    open var isValidName: Bool {
        return (name?.characters.count ?? 0) >= 3
    }

    open var isValidUser: Bool {
        return isValidName && isValidEmail && isValidPassword
    }

    open var isValidImap: Bool {
        return false
    }

    open var isValidSmtp: Bool {
        return false
    }


    /// Returns an Account instance filled with data of self.
    /// It does not deal with Core Data (does not persist).
    /// Only data from this model is taken into account, not needsVerivication or others.
    ///
    /// - Returns: filled Account
    /// - Throws: AccountVerificationError
    open func account() throws -> Account {
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
