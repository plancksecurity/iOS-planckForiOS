//
//  VerifiableAccount.swift
//  pEpForiOS
//
//  Created by buff on 04.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PantomimeFramework
import CoreData

public class VerifiableAccount: VerifiableAccountProtocol {
    // MARK: - VerifiableAccountProtocol (data)

    public weak var verifiableAccountDelegate: VerifiableAccountDelegate?

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
    public var authMethod: AuthMethod?

    public var password: String?

    /**
     If the user chose OAuth2, this is the token. `password` then should be nil.
     */
    public var accessToken: OAuth2AccessTokenProtocol?

    public var serverIMAP: String?
    public var portIMAP: UInt16 = 993
    public var transportIMAP = ConnectionTransport.TLS
    public var serverSMTP: String?
    public var portSMTP: UInt16 = 587
    public var transportSMTP = ConnectionTransport.startTLS

    public var trustedImapServer: Bool

    public init(verifiableAccountDelegate: VerifiableAccountDelegate?,
                address: String?,
                userName: String?,
                loginName: String?,
                authMethod: AuthMethod?,
                password: String?,
                accessToken: OAuth2AccessTokenProtocol?,
                serverIMAP: String?,
                portIMAP: UInt16,
                transportIMAP: ConnectionTransport,
                serverSMTP: String?,
                portSMTP: UInt16,
                transportSMTP: ConnectionTransport,
                trustedImapServer: Bool) {
        self.verifiableAccountDelegate = verifiableAccountDelegate
        self.address = address
        self.userName = userName
        self.loginName = loginName
        self.authMethod = authMethod
        self.password = password
        self.accessToken = accessToken
        self.serverIMAP = serverIMAP
        self .portIMAP = portIMAP
        self.transportIMAP = transportIMAP
        self.serverSMTP = serverSMTP
        self.portSMTP = portSMTP
        self.transportSMTP = transportSMTP
        self.trustedImapServer = trustedImapServer
    }

    public convenience init() {
        self.init(verifiableAccountDelegate: nil,
                  address: nil,
                  userName: nil,
                  loginName: nil,
                  authMethod: nil,
                  password: nil,
                  accessToken: nil,
                  serverIMAP: nil,
                  portIMAP: 993,
                  transportIMAP: ConnectionTransport.TLS,
                  serverSMTP: nil,
                  portSMTP: 587,
                  transportSMTP: ConnectionTransport.startTLS,
                  trustedImapServer: false)
    }

    // MARK: - Internal

    private var imapVerifier: VerifiableAccountIMAP?
    private var smtpVerifier: VerifiableAccountSMTP?

    var imapResult: Result<Void, Error>? = nil
    var smtpResult: Result<Void, Error>? = nil

    /// Used for synchronizing the 2 asynchronous results (IMAP and SMTP verification).
    private let syncQueue = DispatchQueue(label: "VerifiableAccountSynchronization")

    // MARK: - VerifiableAccountProtocol (behavior)

    private func isValid() -> Bool {
        let isValid =
            (address?.count ?? 0) > 0 &&
                ((authMethod == nil && accessToken != nil) ||
                    (authMethod != nil && accessToken == nil) ||
                    (authMethod == nil && accessToken == nil)) &&
                portIMAP > 0 &&
                portSMTP > 0 &&
                (serverIMAP?.count ?? 0) > 0 &&
                (serverSMTP?.count ?? 0) > 0
        return isValid
    }

    private func startImapVerification() throws {
        let theVerifier = VerifiableAccountIMAP()
        self.imapVerifier = theVerifier
        theVerifier.verifiableAccountDelegate = self
        guard let imapConnectInfo = BasicConnectInfo(
            verifiableAccount: self, emailProtocol: .imap) else {
                // Assuming this is caused by invalid data.
                throw VerifiableAccountError.invalidUserData
        }
        theVerifier.verify(basicConnectInfo: imapConnectInfo)
    }

    private func startSmtpVerification() throws {
        let theVerifier = VerifiableAccountSMTP()
        self.smtpVerifier = theVerifier
        theVerifier.verifiableAccountDelegate = self
        guard let smtpConnectInfo = BasicConnectInfo(
            verifiableAccount: self, emailProtocol: .smtp) else {
                // Assuming this is caused by invalid data.
                throw VerifiableAccountError.invalidUserData
        }
        theVerifier.verify(basicConnectInfo: smtpConnectInfo)
    }

    public func verify() throws {
        if !isValid() {
            throw VerifiableAccountError.invalidUserData
        }

        try startImapVerification()
        try startSmtpVerification()
    }

    public func save() throws {
        if !isValid() {
            throw VerifiableAccountError.invalidUserData
        }

        guard let addressImap = serverIMAP else {
            throw VerifiableAccountError.invalidUserData
        }

        guard let addressSmtp = serverSMTP else {
            throw VerifiableAccountError.invalidUserData
        }

        let moc = Record.Context.background

        moc.performAndWait {
            let cdIdentity = createOrUpdateOwnIdentity(context: moc,
                                                       address: address,
                                                       userName: userName)

            let cdAccount = createOrUpdateAccount(context: moc, identity: cdIdentity)

            if let theServer = cdAccount.imapCdServer {
                delete(server: theServer, fromAccount: cdAccount)
            }

            if let theServer = cdAccount.smtpCdServer {
                delete(server: theServer, fromAccount: cdAccount)
            }

            let imapServer = createServer(context: moc,
                                          address: addressImap,
                                          port: portIMAP,
                                          authMethod: authMethod,
                                          trusted: trustedImapServer,
                                          transport: transportIMAP)

            let smtpServer = createServer(context: moc,
                                          address: addressSmtp,
                                          port: portSMTP,
                                          authMethod: authMethod,
                                          trusted: false,
                                          transport: transportSMTP)

            let credentialsImap = createCredentials(context: moc,
                                                    loginName: loginName,
                                                    address: address)
            credentialsImap.servers = NSSet(array: [imapServer])
            imapServer.credentials = credentialsImap

            let credentialsSmtp = createCredentials(context: moc,
                                                    loginName: loginName,
                                                    address: address)
            credentialsSmtp.servers = NSSet(array: [imapServer])
            smtpServer.credentials = credentialsSmtp

            cdAccount.servers = NSSet(array: [imapServer, smtpServer])

            moc.saveAndLogErrors()
        }
    }

    // MARK: - Used by the UI, when using class directly

    public var isValidName: Bool {
        return (userName?.count ?? 0) >= 1
    }

    public var isValidUser: Bool {
        return isValidName && isValidEmail && isValidPassword
    }

    private var isValidEmail: Bool {
        return address?.isProbablyValidEmail() ?? false
    }

    private var isValidPassword: Bool {
        if let pass = password {
            return pass.count > 0
        }
        return false
    }

    // MARK: - Helpers for saving

    /// Deletes the given server from the account, including its credentials
    /// and entries in the key chain.
    private func delete(server: CdServer, fromAccount: CdAccount) {
        if let creds = server.credentials {
            if let key = creds.key {
                KeyChain.updateCreateOrDelete(password: nil, forKey: key)
            }
            server.credentials = nil
            creds.delete()
        }
        fromAccount.removeFromServers(server)
    }

    private func createOrUpdateAccount(context: NSManagedObjectContext,
                                       identity: CdIdentity) -> CdAccount {
        let p = NSPredicate(
            format: "%K = %@" , CdAccount.RelationshipName.identity, identity)
        if let cdAccount = CdAccount.first(predicate: p, in: context) {
            return cdAccount
        } else {
            let cdAccount = CdAccount.create(context: context)
            cdAccount.identity = identity
            return cdAccount
        }
    }

    private func createOrUpdateOwnIdentity(context: NSManagedObjectContext,
                                           address: String?,
                                           userName: String?) -> CdIdentity {
        if let theAddress = address,
            let identity = CdIdentity.search(address: theAddress) {
            update(identity: identity, address: address, userName: userName)
            return identity
        } else {
        let cdId = CdIdentity.create(context: context)
            update(identity: cdId, address: address, userName: userName)
            return cdId
        }
    }

    private func update(identity: CdIdentity,
                        address: String?,
                        userName: String?) {
        identity.address = address
        identity.userName = userName
    }

    private func createCredentials(context: NSManagedObjectContext,
                                   loginName: String?,
                                   address: String?) -> CdServerCredentials {
        let credentials = CdServerCredentials.create(context: context)
        credentials.loginName = loginName ?? address
        // For OAUTH2, deal with the password
        //let thePassword = accessToken?.persistBase64Encoded() ?? password
        credentials.key = accessToken?.keyChainID // TODO Check if that is set by OAUTH2
        return credentials
    }

    private func createServer(context: NSManagedObjectContext,
                              address: String,
                              port: UInt16,
                              authMethod: AuthMethod?,
                              trusted: Bool,
                              transport: ConnectionTransport) -> CdServer {
        let server = CdServer.create(context: context)
        update(server: server,
               address: address,
               port: port,
               authMethod: authMethod,
               trusted: trusted,
               transport: transport)
        return server
    }

    private func update(server: CdServer,
                        address: String,
                        port: UInt16,
                        authMethod: AuthMethod?,
                        trusted: Bool,
                        transport: ConnectionTransport) {
        server.address = serverIMAP
        server.port = NSNumber.init(value: portIMAP)
        server.authMethod = authMethod?.rawValue
        server.serverType = Server.ServerType.imap
        server.trusted = trustedImapServer
        server.transport = transportIMAP.toServerTransport()
    }

    // MARK: - Legacy

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

        let identity = Identity.create(address: address, userID: nil, userName: userName,
                                       isMySelf: true)

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

    // MARK: - Internal (Behaviour)

    private func checkSuccess() {
        guard let theImapResult = imapResult, let theSmtpResult = smtpResult else {
            return
        }

        switch theImapResult {
        case .failure(let error):
            verifiableAccountDelegate?.didEndVerification(result: .failure(error))
        case .success(()):
            switch theSmtpResult {
            case .failure(let error):
                verifiableAccountDelegate?.didEndVerification(result: .failure(error))
            case .success(()):
                verifiableAccountDelegate?.didEndVerification(result: .success(()))
            }
        }
    }
}

extension VerifiableAccount: VerifiableAccountIMAPDelegate {
    public func verified(verifier: VerifiableAccountIMAP,
                         basicConnectInfo: BasicConnectInfo,
                         result: Result<Void, Error>) {
        verifier.verifiableAccountDelegate = nil
        syncQueue.async { [weak self] in
            self?.imapResult = result
            self?.checkSuccess()
        }
    }
}

extension VerifiableAccount: VerifiableAccountSMTPDelegate {
    public func verified(verifier: VerifiableAccountSMTP,
                         basicConnectInfo: BasicConnectInfo,
                         result: Result<Void, Error>) {
        verifier.verifiableAccountDelegate = nil
        syncQueue.async { [weak self] in
            self?.smtpResult = result
            self?.checkSuccess()
        }
    }
}
