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

    public init(account: Account) {
        // We are using a copy of the data here.
        // The outside world must not know changed settings until they have been verified.
        isOAuth2 = account.server(with: .imap)?.authMethod == AuthMethod.saslXoauth2.rawValue
        self.email = account.user.address
        self.loginName = account.server(with: .imap)?.credentials.loginName ?? ""
        self.name = account.user.userName ?? ""

        if let server = account.smtpServer {
            self.smtpServer = ServerViewModel(
                address: server.address,
                port: "\(server.port)",
                transport: server.transport?.asString())
        } else {
            self.smtpServer = ServerViewModel()
        }

        if let server = account.imapServer {
            self.imapServer = ServerViewModel(
                address: server.address,
                port: "\(server.port)",
                transport: server.transport?.asString())
        } else {
            self.imapServer = ServerViewModel()
        }
    }

    private(set) var email: String

    /// - Note: The email model is based on the assumption that imap.loginName == smtp.loginName
    private(set) var loginName: String

    private(set) var name: String

    private(set) var smtpServer: ServerViewModel

    private(set) var imapServer: ServerViewModel

    var verificationService: VerificationService?
    weak var delegate: AccountVerificationResultDelegate?

    /// Holding both the data of the current account in verification,
    /// and also the implementation of the verification.
    private var verifiableAccount: VerifiableAccountProtocol?

    // Currently we assume imap and smtp servers exist already (update).
    // If we run into problems here modify to updateOrCreate.
    func update(loginName: String, name: String, password: String? = nil, imap: ServerViewModel,
                smtp: ServerViewModel) {
        var theVerifier = verifiableAccount ?? VerifiableAccount()
        verifiableAccount = theVerifier

        theVerifier.address = email
        theVerifier.userName = name
        theVerifier.password = password
        if loginName != email {
            theVerifier.loginName = loginName
        }

        if isOAuth2 {
            // TODO: Set correct auth method, etc.
        }

        theVerifier.serverIMAP = imap.address
        if let portString = imap.port, let port = UInt16(portString) {
            theVerifier.portIMAP = port
        }
        let _ = Server.Transport(fromString: imap.transport)
        //  TODO: Set the correct transport

        // TODO: Implement
        /*
        guard let serverImap = account.imapServer,
            let serverSmtp = account.smtpServer else {
                Logger.frontendLogger.errorAndCrash("Account misses imap or smtp server.")
                return
        }
        let pass : String?
        if let p = password {
            pass = p
        } else {
            pass = serverImap.credentials.password
        }
        guard let editedServerImap = server(from: imap, serverType: .imap,
                                            loginName: loginName,
                                            password: pass,
                                            key: serverImap.credentials.key),
            let editedServerSmtp = server(from: smtp,
                                          serverType: .smtp,
                                          loginName: loginName,
                                          password: pass,
                                          key: serverSmtp.credentials.key)
            else {
                Logger.frontendLogger.errorAndCrash("Invalid input.")
                return
        }

        serverImap.updateValues(with: editedServerImap)
        serverSmtp.updateValues(with: editedServerSmtp)

        self.account.user.userName = name

        guard let verificationService = verificationService else {
            Logger.frontendLogger.errorAndCrash("no VerificationService")
            return
        }
        verificationService.requestVerification(account: account, delegate: self)
         */
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
            let address = viewModel.address else {
                Logger.frontendLogger.errorAndCrash("viewModel misses required data.")
                return nil
        }
        let transport = Server.Transport(fromString: viewModel.transport)

        let credentials = ServerCredentials.create(loginName: loginName, key: key)
        if password != nil && password != "" {
            credentials.password = password
        }

        let server = Server.create(serverType: serverType, port: port, address: address,
                                   transport: transport, credentials: credentials)

        return server
    }

    func updateToken(accessToken: OAuth2AccessTokenProtocol) {
        // TODO: What to do here? When does this get called?
        /*
        guard let imapServer = account.imapServer,
            let smtpServer = account.smtpServer else {
                return
        }
        let password = accessToken.persistBase64Encoded()
        imapServer.credentials.password = password
        smtpServer.credentials.password = password
         */
    }
}

// MARK: - AccountVerificationServiceDelegate

extension AccountSettingsViewModel: AccountVerificationServiceDelegate {
    public func verified(account: Account,
                  service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        if result == .ok {
            MessageModelUtil.performAndWait {
                account.save()
            }
        }
        GCD.onMainWait { [weak self] in
            guard let me = self else {
                Logger.frontendLogger.lostMySelf()
                return
            }
            me.delegate?.didVerify(result: result, accountInput: nil)
        }
    }
}
