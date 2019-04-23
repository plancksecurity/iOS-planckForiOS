//
//  VerifiableAccount.swift
//  pEpForiOS
//
//  Created by buff on 04.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import MessageModel
import PantomimeFramework

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
