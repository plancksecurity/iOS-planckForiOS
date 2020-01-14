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
    func showAlertBeforeStoringSecurely(forAccountWith address: String)
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

    mutating func setStoreSecurely(forAccountWith address: String, toValue newValue: Bool) {
        guard let account = Account.Fetch.accountAllowedToManuallyTrust(fromAddress: address) else {
            Log.shared.errorAndCrash("Address should be allowed")
            return
        }
        setStoreSecurely(forAccount: account, toValue: newValue)
    }

    mutating func handleStoreSecurely(forAccountWith address: String, toValue newValue: Bool) {
        guard let account = Account.Fetch.accountAllowedToManuallyTrust(fromAddress: address) else {
            Log.shared.errorAndCrash("Address should be allowed")
            return
        }
        if  shouldShowWaringnBeforeChangingTrustState(forAccount: account, newValue: newValue) {
            delegate?.showAlertBeforeStoringSecurely(forAccountWith: address)
        } else {
            setStoreSecurely(forAccount: account, toValue: newValue)
        }
    }
}

// MARK: - Private

extension TrustedServerSettingsViewModel {
    mutating private func setStoreSecurely(forAccount account: Account, toValue newValue: Bool) {
        for i in 0..<rows.count {
            let row = rows[i]
            if row.address == account.user.address {
                rows[i] = Row(address: row.address, storeMessagesSecurely: newValue)
                break
            }
        }
        account.imapServer?.manuallyTrusted = !newValue
        account.save()
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
