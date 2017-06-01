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

extension AccountSettingsError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .timeOut:
            return NSLocalizedString("Account detection timed out",
                                     comment: "Error description detecting account settings")
        case .notFound:
            return NSLocalizedString("Could not find servers",
                                     comment: "Error description detecting account settings")
        case .illegalValue:
            return NSLocalizedString("Could not find servers",
                                     comment: "Error description detecting account settings")
        }
    }
}

enum AccountVerificationError: Error {
    case insufficientInput
}

enum LoginCellType {
    case Text, Button
}

class LoginViewModel {
    var loginAccount : Account?
    var accountSettings: ASAccountSettings?
    var extendedLogin = false
    let accountVerificationService = AccountVerificationService()
    weak var delegate: AccountVerificationServiceDelegate?

    func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }

    func login(account: String, password: String, username: String? = nil,
               callback: (Error?) -> Void) {
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
        //fast fix remove me
        if username != nil {
            user.username = username
        } else {
            //FIXME
            if acSettings.incoming.username != "" {
                user.username = acSettings.incoming.username
            } else {
                user.username = account
            }
        }
        user.username = account

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

        accountVerificationService.delegate = self
        accountVerificationService.verify(account: account)

        return nil
    }
}

extension LoginViewModel: AccountVerificationServiceDelegate {
    func verified(account: Account, service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        delegate?.verified(account: account, service: service, result: result)
    }
}
