//
//  AccountSettingsViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 13/06/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

public class AccountSettingsViewModel {
    private let logger = Logger(category: Logger.frontend)

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

    private (set) var account: Account
    private let headers = [
        NSLocalizedString("Account", comment: "Account settings"),
        NSLocalizedString("IMAP Settings", comment: "Account settings title IMAP"),
        NSLocalizedString("SMTP Settings", comment: "Account settings title SMTP")
    ]
    private var controlWord = "noRealPassword"

    public let svm = SecurityViewModel()
    public let isOAuth2: Bool

    public init(account: Account) {
        // We are using a copy here. The outside world must not know changed settings until they
        // have been verified.
        self.account = Account(withDataFrom: account)
        isOAuth2 = account.server(with: .imap)?.authMethod == AuthMethod.saslXoauth2.rawValue
    }

    var email: String {
        get {
            return account.user.address
        }
    }

    var loginName: String {
        get {
            // the email model is based on the assumption that imap.loginName == smtp.loginName
            return account.server(with: .imap)?.credentials.loginName ?? ""
        }
    }

    var name: String {
        get {
            return account.user.userName ?? ""
        }
    }

    var smtpServer: ServerViewModel {
        get {
            if let server = account.smtpServer {
                return ServerViewModel(address: server.address,
                                       port: "\(server.port)",
                    transport: server.transport?.asString())
            }
            return ServerViewModel()
        }
    }

    var imapServer: ServerViewModel {
        get {
            if let server = account.imapServer {
                return ServerViewModel(address: server.address,
                                       port: "\(server.port)",
                    transport: server.transport?.asString())
            }
            return ServerViewModel()
        }
    }

    var messageSyncService: MessageSyncServiceProtocol?
    weak var delegate: AccountVerificationResultDelegate?

    //Currently we assume imap and smtp servers exist already (update).
    // If we run into problems here modify to updateOrCreate
    func update(loginName: String, name: String, password: String? = nil, imap: ServerViewModel,
                smtp: ServerViewModel) {
        guard let serverImap = account.imapServer,
            let serverSmtp = account.smtpServer else {
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "Account misses imap or smtp server.")
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
                logger.errorAndCrash("Invalid input.")
                return
        }

        serverImap.updateValues(with: editedServerImap)
        serverSmtp.updateValues(with: editedServerSmtp)

        self.account.user.userName = name

        guard let ms = messageSyncService else {
            logger.errorAndCrash("no MessageSyncService")
            return
        }
        ms.requestVerification(account: account, delegate: self)
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
                Log.shared.errorAndCrash(component: #function,
                                         errorString: "viewModel misses required data.")
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
        guard let imapServer = account.imapServer,
            let smtpServer = account.smtpServer else {
                return
        }
        let password = accessToken.persistBase64Encoded()
        imapServer.credentials.password = password
        smtpServer.credentials.password = password
    }
}

// MARK: - AccountVerificationServiceDelegate

extension AccountSettingsViewModel: AccountVerificationServiceDelegate {
    func verified(account: Account,
                  service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        if result == .ok {
            MessageModel.performAndWait {
                account.save()
            }
        }
        GCD.onMainWait { [weak self] in
            guard let me = self else {
                Logger.lostMySelf(category: Logger.frontend)
                return
            }
            me.delegate?.didVerify(result: result, accountInput: nil)
        }
    }
}
