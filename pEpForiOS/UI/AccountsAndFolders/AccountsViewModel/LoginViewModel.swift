//
//  LoginViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 26/04/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

enum AccountSettingsError: Error {
    case timeOut
    case notFound
    case illegalValue

    init?(status: AS_STATUS) {
        switch status {
        case AS_TIMEOUT:
            self = .timeOut
        case AS_NOT_FOUND:
            self = .notFound
        case AS_ILLEGAL_VALUE:
            self = .illegalValue
        default:
            return nil
        }
    }
}

protocol accountVerificationResultDelegate: class {
    func Result(result: AccountVerificationResult)
}

extension AccountSettingsError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .timeOut:
            return NSLocalizedString("Account detection timed out",
                                     comment: "Error description detecting account settings")
        case .notFound, .illegalValue:
            return NSLocalizedString("Could not find servers",
                                     comment: "Error description detecting account settings")
        }
    }
}

enum AccountVerificationError: Error {
    case insufficientInput
    case noMessageSyncService
}

enum LoginCellType {
    case Text, Button
}

class LoginViewModel {
    var loginAccount : Account?
    var accountSettings: ASAccountSettings?
    var extendedLogin = false
    var messageSyncService: MessageSyncServiceProtocol?
    weak var delegate: accountVerificationResultDelegate?

    init(messageSyncService: MessageSyncService? = nil) {
        self.messageSyncService = messageSyncService
    }

    func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }

    func login(account: String, password: String, login: String? = nil,
               username: String? = nil, callback: (Error?) -> Void) {
        let user = ModelUserInfoTable()
        let acSettings = ASAccountSettings(accountName: account, provider: password,
                                           flags: AS_FLAG_USE_ANY, credentials: nil)
        accountSettings = acSettings
        if let err = AccountSettingsError(status: acSettings.status) {
            Log.shared.error(component: #function, error: err)
            callback(err)
            return
        }
        user.email = account
        user.password = password
        user.portIMAP = UInt16(acSettings.incoming.port)
        user.serverIMAP = acSettings.incoming.hostname
        user.portSMTP = UInt16(acSettings.outgoing.port)
        user.serverSMTP = acSettings.outgoing.hostname
        if login != nil && login != "" {
            user.username = login
        } else {
            //FIXME
            if acSettings.incoming.username != "" {
                user.username = acSettings.incoming.username
            } else {
                user.username = account
            }
        }
        user.name = username
        if let err = verifyAccount(model: user, callback: callback) {
            Log.shared.error(component: #function, error: err)
            callback(AccountSettingsError.illegalValue)
        }
    }

    func verifyAccount(model: ModelUserInfoTable,
                       callback: (Error?) -> Void) -> AccountVerificationError? {
        guard let addres = model.email, let email = model.email,
            let username = model.username, let serverIMAP = model.serverIMAP,
                let serverSMTP = model.serverSMTP else {
            return .insufficientInput
        }
        guard let ms = messageSyncService else {
            return .noMessageSyncService
        }
        let identity = Identity.create(address: addres, userName: email)
        identity.isMySelf = true
        let imapServer = Server.create(serverType: .imap, port: model.portIMAP,
                                       address: serverIMAP,
                                       transport: model.transportIMAP.toServerTransport())
        imapServer.needsVerification = true
        let smtpServer = Server.create(serverType: .smtp, port: model.portSMTP,
                                       address: serverSMTP,
                                       transport: model.transportSMTP.toServerTransport())
        smtpServer.needsVerification = true
        let credentials = ServerCredentials.create(userName: username, password: model.password,
                                                   servers: [imapServer, smtpServer])
        credentials.needsVerification = true
        let account = Account.create(identity: identity, credentials: [credentials])
        loginAccount = account
        account.needsVerification = true
        account.save()

        ms.requestVerification(account: account, delegate: self)

        return nil
    }
}

extension LoginViewModel: AccountVerificationServiceDelegate {
    func verified(account: Account, service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        account.delete()
        delegate?.Result(result: result)
    }
}
