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

    init?(accountSettings: AccountSettingsProtocol) {
        switch accountSettings.status {
        case AS_TIMEOUT:
            self = .timeOut
        case AS_NOT_FOUND:
            self = .notFound
        case AS_ILLEGAL_VALUE:
            self = .illegalValue
        default:
            if let _ = accountSettings.outgoing, let _ = accountSettings.incoming {
                return nil
            } else {
                self = .notFound
            }
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
    var extendedLogin = false
    var messageSyncService: MessageSyncServiceProtocol?
    weak var accountVerificationResultDelegate: AccountVerificationResultDelegate?

    /**
     The last mySelfer, as indicated by login(), so after account verification,
     a key can be generated.
     */
    var mySelfer: KickOffMySelfProtocol?

    init(messageSyncService: MessageSyncServiceProtocol? = nil) {
        self.messageSyncService = messageSyncService
    }

    func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }

    func exist(address: String) -> Bool {
        return Account.by(address: address) != nil
    }

    func login(account: String, password: String, login: String? = nil,
               userName: String? = nil, mySelfer: KickOffMySelfProtocol,
               errorCallback: @escaping (Error) -> Void) {
        self.mySelfer = mySelfer
        let acSettings = AccountSettings(accountName: account, provider: nil,
                                         flags: AS_FLAG_USE_ANY, credentials: nil)
        acSettings.lookupCompletion() { [weak self] settings in
            GCD.onMain() {
                statusOk()
            }
        }

        func statusOk() {
            if let err = AccountSettingsError(accountSettings: acSettings) {
                Log.shared.error(component: #function, error: err)
                errorCallback(err)
                return
            }

            guard let incomingServer = acSettings.incoming,
                let outgoingServer = acSettings.outgoing else {
                    // AccountSettingsError() already handled the error
                    return
            }
            let imapTransport = ConnectionTransport(
                accountSettingsTransport: incomingServer.transport)
            let smtpTransport = ConnectionTransport(
                accountSettingsTransport: outgoingServer.transport)

            let newAccount = AccountUserInput(
                address: account, userName: userName ?? account,
                loginName: login, password: password,
                serverIMAP: incomingServer.hostname,
                portIMAP: UInt16(incomingServer.port),
                transportIMAP: imapTransport,
                serverSMTP: outgoingServer.hostname,
                portSMTP: UInt16(outgoingServer.port),
                transportSMTP: smtpTransport)

            do {
                try verifyAccount(model: newAccount)
            } catch {
                Log.shared.error(component: #function, error: error)
                errorCallback(error)
            }
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
        mySelfer?.startMySelf()
        if result != .ok {
            MessageModel.performAndWait {
                account.delete()
            }
        }
        accountVerificationResultDelegate?.didVerify(result: result)
    }
}
