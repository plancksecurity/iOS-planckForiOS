//
//  LoginViewModel.swift
//  pEpForiOS
//
//  Created by Xavier Algarra on 26/04/2017.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import MessageModel
import pEpIOSToolbox

final class LoginViewModel {
    weak var accountVerificationResultDelegate: AccountVerificationResultDelegate?
    weak var loginViewModelLoginErrorDelegate: LoginViewModelLoginErrorDelegate?

    /// Helper class to handle login logic via OAuth or manual input.
    var loginUtil: LoginUtil

    var isAccountPEPSyncEnable = true {
        didSet {
            loginUtil.verifiableAccount.keySyncEnable = isAccountPEPSyncEnable
        }
    }

    let qualifyServerIsLocalService = QualifyServerIsLocalService()

    init(verifiableAccount: VerifiableAccountProtocol? = nil) {
        loginUtil = LoginUtil(verifiableAccount: verifiableAccount)
        loginUtil.loginProtocolResponseDelegate = self
    }

    func isThereAnAccount() -> Bool {
        return !Account.all().isEmpty
    }

    func exist(address: String) -> Bool {
        return Account.by(address: address) != nil
    }

    /// Depending on `VerifiableAccountProtocol.containsCompleteServerInfo`,
    /// either tries to retrive account settings via a query
    /// to the account settings lib, or procedes directly to attempting a login.
    /// - Parameters:
    ///   - emailAddres: The email of this account
    ///   - displayName: The chosen name of the user, or nick
    ///   - password: The password for the account
    func login(emailAddress: String,
               displayName: String,
               password: String) {
        //Fix later
        loginUtil.login(emailAddress: emailAddress, displayName: displayName, password: password)
    }
}

// MARK: - Private

extension LoginViewModel {

}

// MARK: - LoginProtocolResponseDelegate

extension LoginViewModel : LoginProtocolResponseDelegate {
    func didVerify(result: MessageModel.AccountVerificationResult) {
        accountVerificationResultDelegate?.didVerify(result: result)
    }

    func didFail(error : Error) {
        loginViewModelLoginErrorDelegate?.handle(loginError: error)
    }
}
