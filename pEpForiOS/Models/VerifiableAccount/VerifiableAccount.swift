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

    // MARK: - VerifiableAccountProtocol (behavior)

    private func isValid() -> Bool {
        let isValid =
            (address?.count ?? 0) > 0 &&
                ((authMethod == .saslXoauth2 && accessToken != nil && password == nil) ||
                    (accessToken == nil && password != nil)) &&
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
            let cdIdentity = updateOrCreateOwnIdentity(context: moc,
                                                       address: address,
                                                       userName: userName)

            let cdAccount = findOrCreateAccount(context: moc, identity: cdIdentity)

            let theImapServer = update(
                server: cdAccount.imapCdServer ?? CdServer.create(context: moc),
                address: addressImap,
                port: portIMAP,
                serverType: .imap,
                authMethod: authMethod,
                trusted: trustedImapServer,
                transport: transportIMAP)

            let theSmtpServer = update(
                server: cdAccount.smtpCdServer ?? CdServer.create(context: moc),
                address: addressSmtp,
                port: portSMTP,
                serverType: .smtp,
                authMethod: authMethod,
                trusted: false,
                transport: transportSMTP)

            let credentialsImap = update(
                credentials: theImapServer.credentials ?? CdServerCredentials.create(context: moc),
                loginName: loginName,
                address: address,
                password: password,
                accessToken: accessToken)
            credentialsImap.servers = NSSet(array: [theImapServer])
            theImapServer.credentials = credentialsImap

            let credentialsSmtp = update(
                credentials: theSmtpServer.credentials ?? CdServerCredentials.create(context: moc),
                loginName: loginName,
                address: address,
                password: password,
                accessToken: accessToken)
            credentialsSmtp.servers = NSSet(array: [theSmtpServer])
            theSmtpServer.credentials = credentialsSmtp

            cdAccount.servers = NSSet(array: [theImapServer, theSmtpServer])

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

    // MARK: - Internal (data)

    private var imapVerifier: VerifiableAccountIMAP?
    private var smtpVerifier: VerifiableAccountSMTP?

    var imapResult: Result<Void, Error>? = nil
    var smtpResult: Result<Void, Error>? = nil

    /// Used for synchronizing the 2 asynchronous results (IMAP and SMTP verification).
    private let syncQueue = DispatchQueue(label: "VerifiableAccountSynchronization")

    // MARK: - Internal helpers for saving

    private func findOrCreateAccount(context: NSManagedObjectContext,
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

    private func updateOrCreateOwnIdentity(context: NSManagedObjectContext,
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
        identity.userID = identity.userID ?? CdIdentity.pEpOwnUserID
    }

    /// Updates credentials with the given parameters.
    ///
    /// - Note: There is either an ordinary password, so a key chain entry
    ///         gets produced, or an access token (for OAUTH2),
    ///         in which case the token gets persisted into the key chain.
    private func update(credentials: CdServerCredentials,
                        loginName: String?,
                        address: String?,
                        password: String?,
                        accessToken: OAuth2AccessTokenProtocol?) -> CdServerCredentials {
        credentials.loginName = loginName ?? address

        var payload: String? = nil
        if let token = accessToken {
            payload = token.persistBase64Encoded()
        } else {
            payload = password
        }

        // Reuse key, or create a new one.
        // In any case, update the payload (the password or a current OAUTH2 token).
        let keyChainId = credentials.key ?? UUID().uuidString
        credentials.key = keyChainId
        KeyChain.updateCreateOrDelete(password: payload, forKey: keyChainId)

        return credentials
    }

    private func update(server: CdServer,
                        address: String,
                        port: UInt16,
                        serverType: Server.ServerType,
                        authMethod: AuthMethod?,
                        trusted: Bool,
                        transport: ConnectionTransport) -> CdServer {
        server.address = address
        server.port = NSNumber.init(value: port)
        server.authMethod = authMethod?.rawValue
        server.serverType = serverType
        server.trusted = trusted
        server.transport = transport.toServerTransport()
        server.serverType = serverType

        return server
    }

    // MARK: - Internal delegate helpers

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
