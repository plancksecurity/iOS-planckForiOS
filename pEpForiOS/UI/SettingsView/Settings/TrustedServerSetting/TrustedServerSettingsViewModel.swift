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

    mutating func toggleOnOff(forRowAt index: Int) {
        guard index >= 0 && index < rows.count else {
            Log.shared.errorAndCrash(component: #function, errorString: "Index out of bounds")
            return
        }
        let oldRow = rows[index]
        let toggeled = Row(address: oldRow.address, trusted: !oldRow.trusted)
        rows[index] = toggeled
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
        let servers = Server.Fetch.allAllowedToManuallyTrust()
        let addresses = servers.map { $0.address }
        return addresses
    }
}
