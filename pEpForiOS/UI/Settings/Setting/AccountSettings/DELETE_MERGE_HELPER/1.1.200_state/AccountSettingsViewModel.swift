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

protocol AccountSettingsViewModelDelegate: class {
    func showErrorAlert(error: Error)
    func undoPEPSyncToggle()
    func showLoadingView()
    func hideLoadingView()
}

final class AccountSettingsViewModel {
    let isOAuth2: Bool

    var account: Account
    var count: Int { return headers.count }

    weak var delegate: AccountSettingsViewModelDelegate?

    private let headers = [NSLocalizedString("Account",
                                             comment: "Account settings"),
                           NSLocalizedString("IMAP Settings",
                                             comment: "Account settings title IMAP"),
                           NSLocalizedString("SMTP Settings",
                                             comment: "Account settings title SMTP")]

    /// If there was OAUTH2 for this account, here is a current token.
    /// This trumps both the `originalPassword` and a password given by the user
    /// via the UI.
    /// - Note: For logins that require it, there must be an up-to-date token
    ///         for the verification be able to succeed.
    ///         It is extracted from the existing server credentials on `init`.
    private var accessToken: OAuth2AccessTokenProtocol?

    private enum AccountSettingsError: Error, LocalizedError {
        case accountNotFound, failToModifyAccountPEPSync

        var errorDescription: String? {
            switch self {
            case .accountNotFound, .failToModifyAccountPEPSync:
                return NSLocalizedString("Something went wrong, please try again later", comment: "AccountSettings viewModel: no account error")
            }
        }
    }



    init(account: Account) {
        // We are using a copy of the data here.
        // The outside world must not know changed settings until they have been verified.
        isOAuth2 = account.imapServer?.authMethod == AuthMethod.saslXoauth2.rawValue
        self.account = account
    }

    public func isPEPSyncEnabled(completion: @escaping (Bool) -> ()) {
        account.isKeySyncEnabled(errorCallback: { (_) in
            DispatchQueue.main.async {
                completion(false)
            }
        }) { (isEnabled) in
            DispatchQueue.main.async {
                completion(isEnabled)
            }
        }
    }

    public subscript(section: Int) -> String {
        get {
            assert(sectionIsValid(section: section), "Section out of range")
            return headers[section]
        }
    }

    public func handleResetIdentity() {
        delegate?.showLoadingView()
        account.resetKeys() { [weak self] result in
            guard let me = self else {
                Log.shared.lostMySelf()
                return
            }
            switch result {
            case .success():
                me.delegate?.hideLoadingView()
            case .failure(let error):
                me.delegate?.hideLoadingView()
                me.delegate?.showErrorAlert(error: error)
                Log.shared.errorAndCrash("Fail to reset identity, with error %@ ",
                                         error.localizedDescription)
            }
        }
    }

    public func pEpSync(enable: Bool) {
        account.setKeySyncEnabled(enable: enable,
                                  errorCallback: { [weak self] error in
                                    DispatchQueue.main.async {
                                        guard let me = self else {
                                            // UI, this can happen
                                            return
                                        }
                                        me.delegate?.undoPEPSyncToggle()
                                        me.delegate?.showErrorAlert(error: AccountSettingsError.failToModifyAccountPEPSync)
                                    }
            }, successCallback: {})
    }

    public func updateToken(accessToken: OAuth2AccessTokenProtocol) {
        self.accessToken = accessToken
    }
}

// MARK: - Private

extension AccountSettingsViewModel {
    private func sectionIsValid(section: Int) -> Bool {
        return section >= 0 && section < headers.count
    }
}
