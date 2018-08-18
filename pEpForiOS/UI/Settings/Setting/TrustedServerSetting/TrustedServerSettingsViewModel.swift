//
//  TrustedServerSettingsViewModel.swift
//  pEp
//
//  Created by Andreas Buff on 17.08.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation
import MessageModel

struct TrustedServerSettingsViewModel {
    struct Row: Equatable {
        let address: String
        let trusted: Bool
    }

    private(set) var rows = [Row]()

    init() {
        reset()
    }

    mutating func setTrusted(forAccountWith address: String, toValue newValue: Bool) {
        var rowForAddress: Row?
        for i in 0...rows.count {
            let row = rows[i]
            if row.address == address {
                rowForAddress = row
                rows[i] = Row(address: row.address, trusted: newValue)
                break
            }
        }
        if newValue {
            AppSettings.addToManuallyTrustedServers(address: address)
        } else {
            AppSettings.removeFromManuallyTrustedServers(address: address)
        }
    }

    mutating private func reset() {
        let servers = serversAllowedToManuallyTrust()
        var createes = [Row]()
        for address in servers {
            let isTrusted = AppSettings.manuallyTrustedServers.contains(address)
            createes.append(Row(address: address, trusted: isTrusted))
        }
        rows = createes
    }

    private func serversAllowedToManuallyTrust() -> [String] {
        let accounts = Server.Fetch.allAccountsAllowedToManuallyTrust()
        let addresses = accounts.map { $0.user.address }
        return addresses
    }
}
