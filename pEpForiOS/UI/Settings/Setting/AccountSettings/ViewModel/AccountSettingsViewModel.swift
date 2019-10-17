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

    private(set) var pEpSync: Bool

    /// If there was OAUTH2 for this account, here is a current token.
    /// This trumps both the `originalPassword` and a password given by the user
    /// via the UI.
    /// - Note: For logins that require it, there must be an up-to-date token
    ///         for the verification be able to succeed.
    ///         It is extracted from the existing server credentials on `init`.
    private var accessToken: OAuth2AccessTokenProtocol?
    private var headers: [String] {
        var tempHeader = [NSLocalizedString("Account", comment: "Account settings"),
                          NSLocalizedString("IMAP Settings", comment: "Account settings title IMAP"),
                          NSLocalizedString("SMTP Settings", comment: "Account settings title SMTP")]
        if AppSettings.keySyncEnabled, Account.all().count > 1 {
            tempHeader.append(NSLocalizedString("pEp Sync", comment: "Account settings title pEp Sync"))
        }
        return tempHeader
    }
    private var footers: [String] {
        return [NSLocalizedString("Performs a reset of the privacy settings saved for a communication partner. Could be needed for example if your communication partner cannot read your messages.",
                                  comment: "Footer for Account settings section 1")]
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

    //    private var controlWord = "noRealPassword"

    //    public let svm = SecurityViewModel()

    /// If the credentials have either an IMAP or SMTP password,
    /// it gets stored here.
//    private var originalPassword: String?

    init(account: Account) {
        // We are using a copy of the data here.
        // The outside world must not know changed settings until they have been verified.
        isOAuth2 = account.imapServer?.authMethod == AuthMethod.saslXoauth2.rawValue
        self.account = account

        let pEpSyncState = try? account.isPEPSyncEnabled()
        pEpSync = pEpSyncState ?? false
    }

    func handleResetIdentity() {
        delegate?.showLoadingView()
        account.resetKeys() { [weak self] result in
            switch result {
            case .success():
                self?.delegate?.hideLoadingView()
            case .failure(let error):
                self?.delegate?.hideLoadingView()
                Log.shared.errorAndCrash("Fail to reset identity, with error %@ ",
                                         error.localizedDescription)
            }
        }
    }

    func sectionIsValid(section: Int) -> Bool {
        return section >= 0 && section < headers.count
    }

    func footerFor(section: Int) -> String {
        guard section < footers.count else {
            return ""
        }
        return footers[section]
    }

    func pEpSync(enable: Bool) {
        do {
            try account.pEpSync(enable: enable)
        } catch {
            delegate?.undoPEPSyncToggle()
            delegate?.showErrorAlert(error: AccountSettingsError.failToModifyAccountPEPSync)
        }
    }

    func updateToken(accessToken: OAuth2AccessTokenProtocol) {
        self.accessToken = accessToken
    }
}
