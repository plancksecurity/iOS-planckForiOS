//
//  ConnectionTransport+AccountSettings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

extension ConnectionTransport {
    init(accountSettingsTransport: AccountSettingsServerTransport) {
        switch accountSettingsTransport {
        case .plain: self = .plain
        case .startTLS: self = .startTLS
        case .TLS: self = .TLS
        case .unknown:
            Log.shared.errorAndCrash(
                component: #function,
                errorString: "Unsupported LAS transport: \(accountSettingsTransport)")
            self = .plain
        }
    }
}
