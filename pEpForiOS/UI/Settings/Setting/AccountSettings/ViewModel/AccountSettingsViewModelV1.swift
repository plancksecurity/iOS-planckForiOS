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

final class AccountSettingsViewModelV1 {
    let isOAuth2: Bool

    var account: Account
    var count: Int { return headers.count }

    weak var delegate: AccountSettingsViewModelDelegate?

    private(set) var pEpSync: Bool

    /// If there was OAUTH2 for this account, here is a current token.
    /// This trumps both the `originalPassword` and a password given by the user
    /// via the UI.
    /// - Note: For logins that require it, there must be an up-to-date token
    ///         for the verification be able to succeed.
    ///         It is extracted from the existing server credentials on `init`.
    private var accessToken: OAuth2AccessTokenProtocol?
    private var headers: [String] {
        let tempHeader = [NSLocalizedString("Account", comment: "Account settings"),
                          NSLocalizedString("IMAP Settings", comment: "Account settings title IMAP"),
                          NSLocalizedString("SMTP Settings", comment: "Account settings title SMTP")]
        return tempHeader
    }

    private enum AccountSettingsError: Error, LocalizedError {
        case accountNotFound, failToModifyAccountPEPSync

        var errorDescription: String? {
            switch self {
            case .accountNotFound, .failToModifyAccountPEPSync:
                return NSLocalizedString("Something went wrong, please try again later", comment: "AccountSettings viewModel no account error")
            }
        }
    }

    subscript(section: Int) -> String {
        get {
            assert(sectionIsValid(section: section), "Section out of range")
            return headers[section]
        }
    }

    init(account: Account) {
        // We are using a copy of the data here.
        // The outside world must not know changed settings until they have been verified.
        isOAuth2 = account.imapServer?.authMethod == AuthMethod.saslXoauth2.rawValue
        self.account = account

        let pEpSyncState = try? account.isKeySyncEnabled()
        pEpSync = pEpSyncState ?? false
    }

    func handleResetIdentity() {
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

    func pEpSync(enable: Bool) {
        do {
            try account.setKeySyncEnabled(enable: enable)
        } catch {
            delegate?.undoPEPSyncToggle()
            delegate?.showErrorAlert(error: AccountSettingsError.failToModifyAccountPEPSync)
        }
    }

    func updateToken(accessToken: OAuth2AccessTokenProtocol) {
        self.accessToken = accessToken
    }
}

// MARK: - Private
extension AccountSettingsViewModelV1 {
    private func sectionIsValid(section: Int) -> Bool {
        return section >= 0 && section < headers.count
    }
}
