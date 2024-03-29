//
//  VerifiableAccount.swift
//  pEpForiOS
//
//  Created by buff on 04.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import CoreData

import PantomimeFramework

#if EXT_SHARE
import PlanckToolboxForExtensions
#else
import PlanckToolbox
#endif

extension VerifiableAccount {
    public enum AccountType: CaseIterable {
        case gmail
        case other
        case clientCertificate
        case o365
        case icloud
        case outlook

        public var isOauth: Bool {
            return [.gmail, .o365].contains(self)
        }

        public var accessibilityIdentifier: String {
            switch self {
            case .gmail: return "gmail"
            case .other: return "other"
            case .clientCertificate: return "clientCertificate"
            case .o365: return "o365"
            case .icloud: return "icloud"
            case .outlook: return "outlook"
            }
        }
    }
}

public class VerifiableAccount: VerifiableAccountProtocol {
    private var timeoutVerificationQueue = OperationQueue()
    private var imapVerifier = VerifiableAccountIMAP()
    private var smtpVerifier = VerifiableAccountSMTP()
    private let prepareAccountForSavingService = PrepareAccountForSavingService()
    private var imapResult: Result<Void, Error>? = nil
    private var smtpResult: Result<Void, Error>? = nil

    /// Used for synchronizing the 2 asynchronous results (IMAP and SMTP verification).
    private let syncQueue = DispatchQueue(label: "VerifiableAccountSynchronization")

    /// Someone who tells us whether or not to create a pEp folder for storing sync messages for
    /// synced accounts.
    private let usePlanckFolderProvider: UsePlanckFolderProviderProtocol?

    public var originalImapPassword: String?
    public var originalSmtpPassword: String?

    // MARK: - VerifiableAccountProtocol (delegate)

    public weak var verifiableAccountDelegate: VerifiableAccountDelegate?

    // MARK: - VerifiableAccountProtocol (data)

    public var accountType = AccountType.other
    public var address: String?
    public var userName: String?
    public var authMethod: AuthMethod?
    public var imapPassword: String?
    public var smtpPassword: String?
    public var keySyncEnable: Bool
    public var accessToken: OAuth2AccessTokenProtocol?
    public var clientCertificate: ClientCertificate?
    public var loginNameIMAP: String?
    public var serverIMAP: String?
    public var portIMAP: UInt16 = 993
    public var transportIMAP = ConnectionTransport.TLS
    public var loginNameSMTP: String?
    public var serverSMTP: String?
    public var portSMTP: UInt16 = 587
    public var transportSMTP = ConnectionTransport.startTLS
    public var containsCompleteServerInfo: Bool = false

    // MARK: - Life Cycle

    init(verifiableAccountDelegate: VerifiableAccountDelegate? = nil,
         address: String? = nil,
         userName: String? = nil,
         authMethod: AuthMethod? = nil,
         imapPassword: String? = nil,
         smtpPassword: String? = nil,
         accessToken: OAuth2AccessTokenProtocol? = nil,
         loginNameIMAP: String? = nil,
         serverIMAP: String? = nil,
         portIMAP: UInt16 = 993,
         transportIMAP: ConnectionTransport = ConnectionTransport.TLS,
         loginNameSMTP: String? = nil,
         serverSMTP: String? = nil,
         portSMTP: UInt16 = 587,
         transportSMTP: ConnectionTransport = ConnectionTransport.startTLS,
         keySyncEnable: Bool = true,
         containsCompleteServerInfo: Bool = false,
         usePlanckFolderProvider: UsePlanckFolderProviderProtocol? = nil,
         originalImapPassword: String? = nil,
         originalSmtpPassword: String? = nil) {
        self.verifiableAccountDelegate = verifiableAccountDelegate
        self.address = address
        self.userName = userName
        self.authMethod = authMethod
        self.imapPassword = imapPassword
        self.smtpPassword = smtpPassword
        self.accessToken = accessToken
        self.loginNameIMAP = loginNameIMAP
        self.serverIMAP = serverIMAP
        self.portIMAP = portIMAP
        self.transportIMAP = transportIMAP
        self.loginNameSMTP = loginNameSMTP
        self.serverSMTP = serverSMTP
        self.portSMTP = portSMTP
        self.transportSMTP = transportSMTP
        self.keySyncEnable = keySyncEnable
        self.containsCompleteServerInfo = containsCompleteServerInfo
        self.usePlanckFolderProvider = usePlanckFolderProvider
        self.originalImapPassword = originalImapPassword
        self.originalSmtpPassword = originalSmtpPassword
    }

    // MARK: - VerifiableAccountProtocol (behaviour)


    public func verify() throws {
        imapResult = nil
        smtpResult = nil

        if !isValid() {
            throw VerifiableAccountValidationError.invalidUserData
        }

        try startImapVerification()
        try startSmtpVerification()
        triggerTimoutIn(seconds: 15)
    }

    /// Saves the account if possible.
    /// - Parameter completion: The completion block to be executed.
    public func save(completion: @escaping (Result<Void, Error>) -> ()) {
        do {
            guard let (moc, cdAccount, _, _) = try createAccount() else {
                completion(.failure(VerifiableAccountValidationError.invalidUserData))
                return
            }
            moc.performAndWait { [weak self] in
                guard let me = self else {
                    Log.shared.lostMySelf()
                    return
                }
                let alsoCreatePlanckFolder = me.keySyncEnable && (me.usePlanckFolderProvider?.usePlanckFolder ?? false)
                me.prepareAccountForSavingService.prepareAccount(cdAccount: cdAccount,
                                                                 planckSyncEnable: me.keySyncEnable,
                                                                 alsoCreatePEPFolder: alsoCreatePlanckFolder,
                                                                 context: moc) { success in
                    DispatchQueue.main.async {
                        if success {
                            // The account has been successfully verified and prepared.
                            // We are gonna save it.
                            moc.performAndWait {
                                moc.saveAndLogErrors()
                            }
                            completion(.success(()))
                        } else {
                            moc.performAndWait {
                                moc.rollback()
                            }
                            // Several reasons can end with this error:
                            // - Impossible to get the identity
                            // - Error generating key
                            // - Login operation has errors.
                            // - SyncFoldersFromServerOperation has errors
                            // - CreateIMAPPepFolderOperation has errors
                            completion(.failure(VerifiableAccountValidationError.unknown))
                        }
                    }
                }
            }
        } catch {
            Log.shared.errorAndCrash("Errors thrown should be handled already")
            completion(.failure(VerifiableAccountValidationError.unknown))
        }
    }

    // MARK: - VerifiableAccountProtocol (UI support)

    public var loginNameIsValid: Bool {
        return (loginNameSMTP?.count ?? 0) >= 1 && (loginNameIMAP?.count ?? 0) >= 1
    }

    /// - Note: Does not take the email into account at all for this.
    public var isValidUser: Bool {
        return loginNameIsValid && isValidPassword
    }
}

// MARK: - Private

extension VerifiableAccount {

    /// Check if succeed verifing IMAP, STMP and keyGeneration. If any fails will call fail delegate,
    /// else if all of them succeed, then calls succeed delegate
    private func checkSuccess() {
        guard let theImapResult = imapResult, let theSmtpResult = smtpResult else {
            return
        }

        switch theImapResult {
        case .failure(let error):
            resetPasswordsInKeychain()
            verifiableAccountDelegate?.didEndVerification(result: .failure(error))
        case .success(()):
            switch theSmtpResult {
            case .failure(let error):
                resetPasswordsInKeychain()
                verifiableAccountDelegate?.didEndVerification(result: .failure(error))
            case .success(()):
                verifiableAccountDelegate?.didEndVerification(result: .success(()))
            }
            verifiableAccountDelegate = nil
        }
    }

    // Set the original passwords again to save it in Key Chain.
    // This prevents to have a failing password stored because of the account verification. 
    private func resetPasswordsInKeychain() {
        let context = Stack.shared.newPrivateConcurrentContext
        context.performAndWait {
            if let address = address,
               let cdAccount = CdAccount.by(address: address, context: context) {
                let account = cdAccount.account()
                if let originalPassword = originalImapPassword {
                    account.imapServer?.credentials.password = originalPassword
                }
                if let originalPassword = originalSmtpPassword {
                    account.smtpServer?.credentials.password = originalPassword
                }
            }
        }
    }
}

// MARK: - Private Validation Helpers

extension VerifiableAccount {
    private var isValidPassword: Bool {
        if let imapPass = imapPassword, let smtpPass = smtpPassword {
            return imapPass.count > 0 && smtpPass.count > 0
        }
        return false
    }

    private func isValid() -> Bool {
        let isValid =
            (authMethod == .xoAuth2 || loginNameIsValid) &&
                (authMethod == .xoAuth2 || (loginNameIMAP?.count ?? 0) >= 1) &&
                (authMethod == .xoAuth2 || (loginNameSMTP?.count ?? 0) >= 1) &&
                (address?.count ?? 0) > 0 &&
                ((authMethod == .xoAuth2 && accessToken != nil && imapPassword == nil && smtpPassword == nil) ||
                    (accessToken == nil && imapPassword != nil && smtpPassword != nil)) &&
                portIMAP > 0 &&
                portSMTP > 0 &&
                (serverIMAP?.count ?? 0) > 0 &&
                (serverSMTP?.count ?? 0) > 0
        return isValid
    }

    private func startImapVerification() throws {
        imapVerifier = VerifiableAccountIMAP()
        imapVerifier.delegate = self

        guard let (moc, _, connectInfo, _) = try createAccount() else {
                // Assuming this is caused by invalid data.
                throw VerifiableAccountValidationError.invalidUserData
        }

        moc.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.imapVerifier.verify(connectInfo: connectInfo)
        }
    }

    private func startSmtpVerification() throws {
        smtpVerifier = VerifiableAccountSMTP()
        smtpVerifier.delegate = self

        guard let (moc, _, _, connectInfo) = try createAccount() else {
                // Assuming this is caused by invalid data.
                throw VerifiableAccountValidationError.invalidUserData
        }

        moc.performAndWait {[weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.smtpVerifier.verify(connectInfo: connectInfo)
        }
    }
}

// MARK: - Private helpers for saving

extension VerifiableAccount {
    private func findOrCreateAccount(context: NSManagedObjectContext,
                                     identity: CdIdentity) -> CdAccount {
        let p = CdAccount.PredicateFactory.belongingToIdentity(identity: identity)
        if let cdAccount = CdAccount.first(predicate: p, in: context) {
            return cdAccount
        } else {
            let cdAccount = CdAccount(context: context)
            cdAccount.identity = identity
            return cdAccount
        }
    }

    /// Creates an account for use with verification, on a private session,
    /// but doesn't save it yet.
    /// Throws on validation errors.
    /// - Returns: A 4-tuple consisting of the context the account was created in,
    ///   the account, and IMAP and SMTP connect infos.
    private func createAccount() throws -> (NSManagedObjectContext, CdAccount, EmailConnectInfo, EmailConnectInfo)? {
        if !isValid() {
            throw VerifiableAccountValidationError.invalidUserData
        }

        guard let addressImap = serverIMAP else {
            throw VerifiableAccountValidationError.invalidUserData
        }

        guard let addressSmtp = serverSMTP else {
            throw VerifiableAccountValidationError.invalidUserData
        }

        guard let mailAddress = address else {
            Log.shared.errorAndCrash("We MUST have an address at this point")
            throw VerifiableAccountValidationError.invalidUserData
        }

        let moc = Stack.shared.newPrivateConcurrentContext

        var resultingAccount: CdAccount?
        var imapConnectInfo: EmailConnectInfo?
        var smtpConnectInfo: EmailConnectInfo?

        let clientCertificateObjectID = clientCertificate?.cdObject.objectID
        moc.performAndWait { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost MySelf")
                return
            }

            let cdIdentity = me.updateOrCreateOwnIdentity(context: moc,
                                                          address: mailAddress,
                                                          userName: me.userName)

            // `updateOrCreate` never changes user name for own identites.
            // Thus we have to do it explicitly.
            cdIdentity.userName = me.userName

            let cdAccount = me.findOrCreateAccount(context: moc, identity: cdIdentity)

            resultingAccount = cdAccount

            let theImapServer = me.update(
                server: cdAccount.server(type: .imap) ?? CdServer(context: moc),
                address: addressImap,
                port: me.portIMAP,
                serverType: .imap,
                authMethod: me.authMethod,
                transport: me.transportIMAP)

            let theSmtpServer = me.update(
                server: cdAccount.server(type: .smtp) ?? CdServer(context: moc),
                address: addressSmtp,
                port: me.portSMTP,
                serverType: .smtp,
                authMethod: me.authMethod,
                transport: me.transportSMTP)

            var cdClientCertificate: CdClientCertificate? = nil
            if let clientCertificateObjectID = clientCertificateObjectID {
                cdClientCertificate = moc.object(with: clientCertificateObjectID) as? CdClientCertificate
            }

            let credentialsImap = me.update(
                credentials: theImapServer.credentials ?? CdServerCredentials(context: moc),
                loginName: me.loginNameIMAP,
                address: me.address,
                password: me.imapPassword,
                clientCertificate: cdClientCertificate,
                accessToken: me.accessToken)
            credentialsImap.servers = NSSet(array: [theImapServer])
            theImapServer.credentials = credentialsImap

            let credentialsSmtp = me.update(
                credentials: theSmtpServer.credentials ?? CdServerCredentials(context: moc),
                loginName: me.loginNameSMTP,
                address: me.address,
                password: me.smtpPassword,
                clientCertificate: cdClientCertificate,
                accessToken: me.accessToken)
            credentialsSmtp.servers = NSSet(array: [theSmtpServer])
            theSmtpServer.credentials = credentialsSmtp

            cdAccount.servers = NSSet(array: [theImapServer, theSmtpServer])
            imapConnectInfo = cdAccount.imapConnectInfo
            smtpConnectInfo = cdAccount.smtpConnectInfo
        }

        if let theAccount = resultingAccount,
            let theImapConnectInfo = imapConnectInfo,
            let theSmtpConnectInfo = smtpConnectInfo {
            return (moc, theAccount, theImapConnectInfo, theSmtpConnectInfo)
        } else {
            return nil
        }
    }

    private func updateOrCreateOwnIdentity(context: NSManagedObjectContext,
                                           address: String,
                                           userName: String?) -> CdIdentity {
        let identity = CdIdentity.updateOrCreate(withAddress: address,
                                                 userID: CdIdentity.pEpOwnUserID,
                                                 addressBookID: nil,
                                                 userName: userName,
                                                 context: context)
        return identity
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
                        clientCertificate: CdClientCertificate?,
                        accessToken: OAuth2AccessTokenProtocol?) -> CdServerCredentials {
        credentials.loginName = loginName ?? address
        credentials.clientCertificate = clientCertificate

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
                        transport: ConnectionTransport) -> CdServer {
        server.address = address
        server.port = Int32(port)
        server.authMethod = authMethod?.rawValue
        server.serverType = serverType
        server.transport = transport.toServerTransport()
        server.serverType = serverType

        return server
    }

    /// Trigger a timeout error on the verification process after seconds passed by param.
    ///
    /// - Parameter seconds: The seconds to trigger the timeout.
    private func triggerTimoutIn(seconds: TimeInterval) {
        if MiscUtil.isUnitTest() {
            return
        }

        DispatchQueue(label: "VerificationTimeoutQueue", qos: .default)
            .asyncAfter(deadline: .now() + seconds) { [weak self] in
            guard let me = self else {
                // Self might be gone, nothing to do
                return
            }
            me.timeoutVerificationQueue.addOperation {
                guard let me = self else {
                    //The account has been verified.
                    return
                }
                me.imapVerifier.stop()
                me.smtpVerifier.stop()

                let smtpError = SmtpSendError.connectionTimedOut(#function, "Timeout")
                me.smtpResult = .failure(smtpError)
                let imapError = ImapSyncOperationError.connectionTimedOut(#function)
                me.imapResult = .failure(imapError)
                me.checkSuccess()
                me.imapResult = nil
                me.smtpResult = nil
            }
        }
    }
}

// MARK: - VerifiableAccountIMAPDelegate

extension VerifiableAccount: VerifiableAccountIMAPDelegate {
    func verified(verifier: VerifiableAccountIMAP,
                  result: Result<Void, Error>) {
        timeoutVerificationQueue.cancelAllOperations()
        syncQueue.async { [weak self] in
            self?.imapResult = result
            self?.checkSuccess()
        }
    }
}

// MARK: - VerifiableAccountSMTPDelegate

extension VerifiableAccount: VerifiableAccountSMTPDelegate {
    func verified(verifier: VerifiableAccountSMTP,
                  result: Result<Void, Error>) {
        syncQueue.async { [weak self] in
            self?.smtpResult = result
            self?.checkSuccess()
        }
    }
}

// MARK: - VerifiableAccount Factory

extension VerifiableAccount {
    /// Returns: A possibly preconfigured `VerifiableAccountProtocol` for the given
    /// account type.
    /// See `VerifiableAccountProtocol.containsCompleteServerInfo`
    /// to find out if server data is still missing or not.
    /// - Parameter type: The account type
    public static func verifiableAccount(for type: AccountType,
                                         usePlanckFolderProvider: UsePlanckFolderProviderProtocol? = nil,
                                         originalImapPassword: String? = nil,
                                         originalSmtpPassword: String? = nil) -> VerifiableAccountProtocol {
        var account =  VerifiableAccount(verifiableAccountDelegate: nil,
                                         address: nil,
                                         userName: nil,
                                         authMethod: .cramMD5,
                                         imapPassword: nil,
                                         smtpPassword: nil,
                                         accessToken: nil,
                                         loginNameIMAP: nil,
                                         serverIMAP: nil,
                                         portIMAP: 993,
                                         transportIMAP: .TLS,
                                         loginNameSMTP: nil,
                                         serverSMTP: nil,
                                         portSMTP: 465,
                                         transportSMTP: .TLS,
                                         keySyncEnable: true,
                                         containsCompleteServerInfo: false,
                                         usePlanckFolderProvider: usePlanckFolderProvider,
                                         originalImapPassword: originalImapPassword,
                                         originalSmtpPassword: originalSmtpPassword)

        switch type {
        case .gmail:
            account = VerifiableAccount(verifiableAccountDelegate: nil,
                                        address: nil,
                                        userName: nil,
                                        authMethod: .xoAuth2,
                                        imapPassword: nil,
                                        smtpPassword: nil,
                                        accessToken: nil,
                                        loginNameIMAP: nil,
                                        serverIMAP: "imap.gmail.com",
                                        portIMAP: 993,
                                        transportIMAP: .TLS,
                                        loginNameSMTP: nil,
                                        serverSMTP: "smtp.gmail.com",
                                        portSMTP: 465,
                                        transportSMTP: .TLS,
                                        keySyncEnable: true,
                                        containsCompleteServerInfo: true,
                                        usePlanckFolderProvider: usePlanckFolderProvider)
        case .o365:
            account = VerifiableAccount(verifiableAccountDelegate: nil,
                                        address: nil,
                                        userName: nil,
                                        authMethod: .cramMD5,
                                        imapPassword: nil,
                                        smtpPassword: nil,
                                        accessToken: nil,
                                        loginNameIMAP: nil,
                                        serverIMAP: "outlook.office365.com",
                                        portIMAP: 993,
                                        transportIMAP: .TLS,
                                        loginNameSMTP: nil,
                                        serverSMTP: "smtp.office365.com",
                                        portSMTP: 587,
                                        transportSMTP: .startTLS,
                                        keySyncEnable: true,
                                        containsCompleteServerInfo: true,
                                        usePlanckFolderProvider: usePlanckFolderProvider)
        case .icloud:
            account =  VerifiableAccount(verifiableAccountDelegate: nil,
                                         address: nil,
                                         userName: nil,
                                         authMethod: .cramMD5,
                                         imapPassword: nil,
                                         smtpPassword: nil,
                                         accessToken: nil,
                                         loginNameIMAP: nil,
                                         serverIMAP: "imap.mail.me.com",
                                         portIMAP: 993,
                                         transportIMAP: .TLS,
                                         loginNameSMTP: nil,
                                         serverSMTP: "smtp.mail.me.com",
                                         portSMTP: 587,
                                         transportSMTP: .startTLS,
                                         keySyncEnable: true,
                                         containsCompleteServerInfo: true,
                                         usePlanckFolderProvider: usePlanckFolderProvider)
        case .outlook:
            account =  VerifiableAccount(verifiableAccountDelegate: nil,
                                         address: nil,
                                         userName: nil,
                                         authMethod: .cramMD5,
                                         imapPassword: nil,
                                         smtpPassword: nil,
                                         accessToken: nil,
                                         loginNameIMAP: nil,
                                         serverIMAP: "outlook.office365.com",
                                         portIMAP: 993,
                                         transportIMAP: .TLS,
                                         loginNameSMTP: nil,
                                         serverSMTP: "smtp.office365.com",
                                         portSMTP: 587,
                                         transportSMTP: .startTLS,
                                         keySyncEnable: true,
                                         containsCompleteServerInfo: true,
                                         usePlanckFolderProvider: usePlanckFolderProvider)
        case .other, .clientCertificate:
            break
        }

        account.accountType = type
        return account
    }
}
