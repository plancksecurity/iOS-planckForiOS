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

    /// /// Handle setting an account securely. Will not show any alert to confirm the acction
    /// - Parameters:
    ///   - indexPath: indexPath of the cell that trigger the action
    ///   - newValue: new value of the Switch of the cell that trigger the action
    mutating func setStoreSecurely(forIndexPath indexPath: IndexPath, toValue newValue: Bool) {
        guard let account = account(fromIndexPath: indexPath) else {
            Log.shared.errorAndCrash("Address should be allowed")
            return
        }

        updateRowData(forIndexPath: indexPath, toValue: newValue)
        setStoreSecurely(forAccount: account, toValue: newValue)
    }

    /// Handle setting an account securely. If the account server is not  will show an alert to confirm the acction
    /// - Parameters:
    ///   - indexPath: indexPath of the cell that trigger the action
    ///   - newValue: new value of the Switch of the cell that trigger the action
    mutating func handleStoreSecurely(forIndexPath indexPath: IndexPath, toValue newValue: Bool) {
        guard let account = account(fromIndexPath: indexPath) else {
            Log.shared.errorAndCrash("Address should be allowed")
            return
        }

        if  shouldShowWaringnBeforeChangingTrustState(forAccount: account, newValue: newValue) {
            delegate?.showAlertBeforeStoringSecurely(forIndexPath: indexPath)
        } else {
            updateRowData(forIndexPath: indexPath, toValue: newValue)
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
        account.save()
    }

    mutating private func updateRowData(forIndexPath indexPath: IndexPath,
                                              toValue newValue: Bool) {
        var row = rows[indexPath.row]
        row = Row(address: row.address, storeMessagesSecurely: newValue)
    }

    private func shouldShowWaringnBeforeChangingTrustState(forAccount account: Account,
                                                           newValue: Bool) -> Bool {
        return  newValue && account.shouldShowWaringnBeforeTrusting
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
