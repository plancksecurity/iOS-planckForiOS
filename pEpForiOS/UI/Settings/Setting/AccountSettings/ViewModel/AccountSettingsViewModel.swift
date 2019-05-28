//
//  AccountSettingsViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 13/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

import PantomimeFramework

public class AccountSettingsViewModel {
    public struct ServerViewModel {
        var address: String?
        var port: String?
        var transport: String?
    }

    public struct SecurityViewModel {
        var options = Server.Transport.toArray()
        var size : Int {
            get {
                return options.count
            }
        }

        subscript(option: Int) -> String {
            get {
                return options[option].asString()
            }
        }
    }

    private let headers = [
        NSLocalizedString("Account", comment: "Account settings"),
        NSLocalizedString("IMAP Settings", comment: "Account settings title IMAP"),
        NSLocalizedString("SMTP Settings", comment: "Account settings title SMTP")
    ]
    private var controlWord = "noRealPassword"

    public let svm = SecurityViewModel()
    public let isOAuth2: Bool

    /// Holding both the data of the current account in verification,
    /// and also the implementation of the verification.
    public var verifiableAccount: VerifiableAccountProtocol?

    var messageModelService: MessageModelService

    public init(account: Account, messageModelService: MessageModelService) {
        self.messageModelService = messageModelService

        // We are using a copy of the data here.
        // The outside world must not know changed settings until they have been verified.
        isOAuth2 = account.imapServer?.authMethod == AuthMethod.saslXoauth2.rawValue
        self.email = account.user.address
        self.loginName = account.imapServer?.credentials.loginName ?? ""
        self.name = account.user.userName ?? ""

        if let server = account.imapServer {
            self.originalPassword = server.credentials.password
            self.imapServer = ServerViewModel(
                address: server.address,
                port: "\(server.port)",
                transport: server.transport.asString())
        } else {
            self.imapServer = ServerViewModel()
        }

        if let server = account.smtpServer {
            self.originalPassword = self.originalPassword ?? server.credentials.password
            self.smtpServer = ServerViewModel(
                address: server.address,
                port: "\(server.port)",
                transport: server.transport.asString())
        } else {
            self.smtpServer = ServerViewModel()
        }

        if isOAuth2 {
            if let payload = account.imapServer?.credentials.password ??
                account.smtpServer?.credentials.password,
                let token = OAuth2AccessToken.from(base64Encoded: payload)
                    as? OAuth2AccessTokenProtocol {
                self.accessToken = token
            } else {
                Log.shared.errorAndCrash("Supposed to do OAUTH2, but no existing token")
            }
        }
    }

    private(set) var email: String

    /// - Note: The email model is based on the assumption that imap.loginName == smtp.loginName
    private(set) var loginName: String

    private(set) var name: String

    private(set) var smtpServer: ServerViewModel

    private(set) var imapServer: ServerViewModel

    weak var delegate: AccountVerificationResultDelegate?

    /// If the credentials have either an IMAP or SMTP password,
    /// it gets stored here.
    private var originalPassword: String?

    /// If there was OAUTH2 for this account, here is a current token.
    /// This trumps both the `originalPassword` and a password given by the user
    /// via the UI.
    /// - Note: For logins that require it, there must be an up-to-date token
    ///         for the verification be able to succeed.
    ///         It is extracted from the existing server credentials on `init`.
    private var accessToken: OAuth2AccessTokenProtocol?

    func update(loginName: String, name: String, password: String? = nil, imap: ServerViewModel,
                smtp: ServerViewModel) {
        var theVerifier = verifiableAccount ??
            VerifiableAccount(messageModelService: messageModelService)
        verifiableAccount = theVerifier

        theVerifier.address = email
        theVerifier.userName = name

        if loginName != email {
            theVerifier.loginName = loginName
        }

        if isOAuth2 {
            if self.accessToken == nil {
                Log.shared.errorAndCrash("Have to do OAUTH2, but lacking current token")
            }
            theVerifier.authMethod = .saslXoauth2
            theVerifier.accessToken = accessToken
            // OAUTH2 trumps any password
            theVerifier.password = nil
        } else {
            theVerifier.password = originalPassword
            if password != nil {
                theVerifier.password = password
            }
        }

        // IMAP
        theVerifier.serverIMAP = imap.address
        if let portString = imap.port, let port = UInt16(portString) {
            theVerifier.portIMAP = port
        }
        if let transport = Server.Transport(fromString: imap.transport) {
            theVerifier.transportIMAP = ConnectionTransport.init(transport: transport)
        }

        // SMTP
        theVerifier.serverSMTP = smtp.address
        if let portString = smtp.port, let port = UInt16(portString) {
            theVerifier.portSMTP = port
        }
        if let transport = Server.Transport(fromString: smtp.transport) {
            theVerifier.transportSMTP = ConnectionTransport.init(transport: transport)
        }

        theVerifier.verifiableAccountDelegate = self

        do {
            try theVerifier.verify()
        } catch {
            delegate?.didVerify(result: .noImapConnectData)
        }
    }

    func sectionIsValid(section: Int) -> Bool {
        return section >= 0 && section < headers.count
    }

    var count: Int {
        get {
            return headers.count
        }
    }

    subscript(section: Int) -> String {
        get {
            assert(sectionIsValid(section: section), "Section out of range")
            return headers[section]
        }
    }

    private func server(from viewModel:ServerViewModel, serverType:Server.ServerType,
                        loginName: String, password: String?, key: String? = nil) -> Server? {
        guard let viewModelPort = viewModel.port,
            let port = UInt16(viewModelPort),
            let address = viewModel.address,
            let transport = Server.Transport(fromString: viewModel.transport) else {
                Log.shared.errorAndCrash("viewModel misses required data.")
                return nil
        }

        let credentials = ServerCredentials.create(loginName: loginName, key: key)
        if password != nil && password != "" {
            credentials.password = password
        }

        let server = Server.create(serverType: serverType, port: port, address: address,
                                   transport: transport, credentials: credentials)

        return server
    }

    func updateToken(accessToken: OAuth2AccessTokenProtocol) {
        self.accessToken = accessToken
    }
}

// MARK: - VerifiableAccountDelegate

extension AccountSettingsViewModel: VerifiableAccountDelegate {
    public func didEndVerification(result: Result<Void, Error>) {
        switch result {
        case .success(()):
            do {
                try verifiableAccount?.save()
                delegate?.didVerify(result: .ok)
            } catch {
                Log.shared.errorAndCrash("%@", error.localizedDescription)
            }
        case .failure(let error):
            if let imapError = error as? ImapSyncError {
                delegate?.didVerify(
                    result: .imapError(imapError))
            } else if let smtpError = error as? SmtpSendError {
                delegate?.didVerify(
                    result: .smtpError(smtpError))
            } else {
                Log.shared.errorAndCrash("%@", error.localizedDescription)
            }
        }
    }
}
