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

struct TrustedServerSettingsViewModel {
    struct Row: Equatable {
        let address: String
        let storeMessagesSecurely: Bool
    }

    private(set) var rows = [Row]()

    init() {
        reset()
    }

    mutating func setStoreSecurely(forAccountWith address: String, toValue newValue: Bool) {
        guard let account = Account.Fetch.accountAllowedToManuallyTrust(fromAddress: address) else {
            Logger.frontendLogger.errorAndCrash("Address should be allowed")
            return
        }

        for i in 0..<rows.count {
            let row = rows[i]
            if row.address == address {
                rows[i] = Row(address: row.address, storeMessagesSecurely: newValue)
                break
            }
        }
        account.imapServer?.manuallyTrusted = !newValue
        account.save()
    }

    mutating private func reset() {
        let accounts = Account.Fetch.allAccountsAllowedToManuallyTrust()
        var createes = [Row]()
        for account in accounts {
            guard let isTrusted = account.imapServer?.manuallyTrusted else {
                Logger.frontendLogger.errorAndCrash("Trusted server has no imapServer")
                continue
            }
            createes.append(Row(address: account.user.address, storeMessagesSecurely: !isTrusted))
        }
        rows = createes
    }
}
