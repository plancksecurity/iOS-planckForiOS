//
//  EditableAccountSettingsViewModel.swift
//  pEp
//
//  Created by Alejandro Gelos on 08/10/2019.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

final class EditableAccountSettingsViewModel {
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

    /// - Note: The email model is based on the assumption that imap.loginName == smtp.loginName
    private(set) var email: String
    private(set) var name: String
    private(set) var loginName: String
    private(set) var smtpServer: ServerViewModel
    private(set) var imapServer: ServerViewModel

    public let isOAuth2: Bool

    /// If the credentials have either an IMAP or SMTP password,
    /// it gets stored here.
    private var originalPassword: String?

    var messageModelService: MessageModelServiceProtocol

    /// Holding both the data of the current account in verification,
    /// and also the implementation of the verification.
    public var verifiableAccount: VerifiableAccountProtocol?
    weak var verifiableDelegate: AccountVerificationResultDelegate?


    /// If there was OAUTH2 for this account, here is a current token.
    /// This trumps both the `originalPassword` and a password given by the user
    /// via the UI.
    /// - Note: For logins that require it, there must be an up-to-date token
    ///         for the verification be able to succeed.
    ///         It is extracted from the existing server credentials on `init`.
    private var accessToken: OAuth2AccessTokenProtocol?

    public init(account: Account, messageModelService: MessageModelServiceProtocol) {
        self.messageModelService = messageModelService

        // We are using a copy of the data here.
        // The outside world must not know changed settings until they have been verified.
        isOAuth2 = account.imapServer?.authMethod == AuthMethod.saslXoauth2.rawValue
        email = account.user.address
        loginName = account.imapServer?.credentials.loginName ?? ""
        name = account.user.userName ?? ""

        if let server = account.imapServer {
            originalPassword = server.credentials.password
            imapServer = ServerViewModel(address: server.address,
                                         port: "\(server.port)",
                                         transport: server.transport.asString())
        } else {
            imapServer = ServerViewModel()
        }

        if let server = account.smtpServer {
            originalPassword = originalPassword ?? server.credentials.password
            smtpServer = ServerViewModel(address: server.address,
                                         port: "\(server.port)",
                                         transport: server.transport.asString())
        } else {
            smtpServer = ServerViewModel()
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

    func update(loginName: String,
                name: String,
                password: String? = nil,
                imap: ServerViewModel,
                smtp: ServerViewModel) {
        var theVerifier = verifiableAccount ??
            VerifiableAccount(messageModelService: messageModelService)
        theVerifier.verifiableAccountDelegate = self
        verifiableAccount = theVerifier

        theVerifier.address = email
        theVerifier.userName = name
        theVerifier.loginName = loginName

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

        do {
            try theVerifier.verify()
        } catch {
            verifiableDelegate?.didVerify(result: .noImapConnectData)
        }
    }
}

// MARK: - VerifiableAccountDelegate

extension EditableAccountSettingsViewModel: VerifiableAccountDelegate {
    public func didEndVerification(result: Result<Void, Error>) {
        switch result {
        case .success(()):
            do {
                try verifiableAccount?.save { [weak self] _ in
                    self?.verifiableDelegate?.didVerify(result: .ok)
                }
            } catch {
                Log.shared.errorAndCrash(error: error)
                verifiableDelegate?.didVerify(result: .ok)
            }
        case .failure(let error):
            if let imapError = error as? ImapSyncError {
                verifiableDelegate?.didVerify(
                    result: .imapError(imapError))
            } else if let smtpError = error as? SmtpSendError {
                verifiableDelegate?.didVerify(
                    result: .smtpError(smtpError))
            } else {
                Log.shared.errorAndCrash(error: error)
            }
        }
    }
}
