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

protocol AccountVerificationResultDelegate: class {
    func didVerify(result: AccountVerificationResult)
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

enum LoginCellType {
    case Text, Button
}

class LoginViewModel {
    var loginAccount : Account?
    var accountSettings: ASAccountSettings?
    var extendedLogin = false
    var messageSyncService: MessageSyncServiceProtocol?
    weak var delegate: AccountVerificationResultDelegate?

    init(messageSyncService: MessageSyncService? = nil) {
        self.messageSyncService = messageSyncService
    }

    func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }

    func login(account: String, password: String, login: String? = nil,
               username: String? = nil, callback: (Error?) -> Void) {
        var user = AccountUserInput()
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

        do {
            try verifyAccount(model: user)
        } catch {
            Log.shared.error(component: #function, error: error)
            callback(error)
        }
    }

    /// Creates and persits an account with given data and triggers a verification request.
    ///
    /// - Parameter model: account data
    /// - Throws: AccountVerificationError
    func verifyAccount(model: AccountUserInput) throws {
        guard let ms = messageSyncService else {
            Log.shared.errorAndCrash(component: #function, errorString: "no MessageSyncService")
            return
        }
        do {
            let account = try model.account()
            loginAccount = account
            account.needsVerification = true
            account.save()
            ms.requestVerification(account: account, delegate: self)
        } catch {
            throw error
        }
    }
}

extension LoginViewModel: AccountVerificationServiceDelegate {
    func verified(account: Account, service: AccountVerificationServiceProtocol,
                  result: AccountVerificationResult) {
        delegate?.didVerify(result: result)
    }
}
