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

protocol AccountSettingsViewModelDelegate: class {
    func showErrorAlert(title: String, message: String, buttonTitle: String)
    func undoPEPSyncToggle()
    func showLoadingView()
    func hideLoadingView()
}

public class AccountSettingsViewModel {

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
        return [NSLocalizedString("Performs a reset of the privacy settings saved for a communication partner. Could be needed for example if your communication partner cannot read your messages.", comment: "Footer for Account settings section 1")]
    }
//    private var controlWord = "noRealPassword"

//    public let svm = SecurityViewModel()
    public let isOAuth2: Bool

    var account: Account
    private(set) var pEpSync: Bool

    weak var delegate: AccountSettingsViewModelDelegate?

    /// If the credentials have either an IMAP or SMTP password,
    /// it gets stored here.
//    private var originalPassword: String?

    private enum AccountSettingsError: Error, LocalizedError {
        case accountNotFound, failToModifyAccountPEPSync

        public var errorDescription: String? {
            switch self {
            case .accountNotFound, .failToModifyAccountPEPSync:
                return NSLocalizedString("Something went wrong, please try again later", comment: "AccountSettings viewModel no account error")
            }
        }
    }

    /// If there was OAUTH2 for this account, here is a current token.
    /// This trumps both the `originalPassword` and a password given by the user
    /// via the UI.
    /// - Note: For logins that require it, there must be an up-to-date token
    ///         for the verification be able to succeed.
    ///         It is extracted from the existing server credentials on `init`.
    private var accessToken: OAuth2AccessTokenProtocol?

    public init(account: Account) {

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

    func footerFor(section: Int) -> String {
        if section < footers.count {
            return footers[section]
        }
        return ""
    }

    func pEpSync(enable: Bool) {
        do {
            try account.pEpSync(enable: enable)
        } catch {
            delegate?.undoPEPSyncToggle()
            showErrorAlert(message: AccountSettingsError.failToModifyAccountPEPSync.localizedDescription)
        }
    }

    func updateToken(accessToken: OAuth2AccessTokenProtocol) {
        self.accessToken = accessToken
    }

    private func showErrorAlert(message: String) {
        let title = NSLocalizedString("Error", comment: "Fail to update pEpSync value alert title")
        let buttonTitle = NSLocalizedString("OK", comment: "OK button for pEpSyncError alert")
        delegate?.showErrorAlert(title: title, message: message, buttonTitle: buttonTitle)
    }
}
