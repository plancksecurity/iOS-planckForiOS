//
//  TrustedServerSettingsViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 17.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel
import pEpIOSToolbox

protocol TrustedServerSettingsViewModelDelegate: class {
    func showAlertBeforeStoringSecurely(forIndexPath indexPath: IndexPath)
}

struct TrustedServerSettingsViewModel {
    struct Row: Equatable {
        let address: String
        let storeMessagesSecurely: Bool
    }

    private(set) var rows = [Row]()
    weak var delegate: TrustedServerSettingsViewModelDelegate?

    init() {
        reset()
    }

    /// Handle setting an account securely. Will not show any alert to confirm the acction
    /// - Parameters:
    ///   - indexPath: indexPath of the cell that trigger the action
    ///   - newValue: new value of the Switch of the cell that trigger the action
    mutating func setStoreSecurely(indexPath: IndexPath, toValue newValue: Bool) {
        guard let account = account(fromIndexPath: indexPath) else {
            Log.shared.errorAndCrash("No address found")
            return
        }

        updateRowData(indexPath: indexPath, toValue: newValue)
        setStoreSecurely(forAccount: account, toValue: newValue)
    }

    /// Handle setting an account securely. If the account server is not  will show an alert to confirm the acction
    /// - Parameters:
    ///   - indexPath: indexPath of the cell that trigger the action
    ///   - newValue: new value of the Switch of the cell that trigger the action
    mutating func handleStoreSecurely(indexPath: IndexPath, toValue newValue: Bool) {
        guard let account = account(fromIndexPath: indexPath) else {
            Log.shared.errorAndCrash("No address found")
            return
        }

        if  shouldShowWaringnBeforeChangingTrustState(forAccount: account, storeSecurely: newValue) {
            delegate?.showAlertBeforeStoringSecurely(forIndexPath: indexPath)
        } else {
            updateRowData(indexPath: indexPath, toValue: newValue)
            setStoreSecurely(forAccount: account, toValue: newValue)
        }
    }
}

// MARK: - Private

extension TrustedServerSettingsViewModel {
    private func account(fromIndexPath indexPath: IndexPath) -> Account? {
        let address = rows[indexPath.row].address
        return Account.Fetch.accountAllowedToManuallyTrust(fromAddress: address)
    }

    private func setStoreSecurely(forAccount account: Account, toValue newValue: Bool) {
        account.imapServer?.manuallyTrusted = !newValue
        account.session.commit()
    }

    mutating private func updateRowData(indexPath: IndexPath, toValue newValue: Bool) {
        let row = rows[indexPath.row]
        rows[indexPath.row] = Row(address: row.address, storeMessagesSecurely: newValue)
    }

    private func shouldShowWaringnBeforeChangingTrustState(forAccount account: Account,
                                                           storeSecurely: Bool) -> Bool {
        return !storeSecurely && account.shouldShowWaringnBeforeTrusting
    }

    mutating private func reset() {
        let accounts = Account.Fetch.allAccountsAllowedToManuallyTrust()
        var createes = [Row]()
        for account in accounts {
            guard let isTrusted = account.imapServer?.manuallyTrusted else {
                Log.shared.errorAndCrash("Trusted server has no imapServer")
                continue
            }
            createes.append(Row(address: account.user.address, storeMessagesSecurely: !isTrusted))
        }
        rows = createes
    }
}
