//
//  AccountSettingsError.swift
//  pEp
//
//  Created by Dirk Zimmermann on 26.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

extension AccountSettings {
    enum AccountSettingsError: Error {
        case timeOut
        case notFound
        case illegalValue

        init?(accountSettings: AccountSettingsProtocol) {
            switch accountSettings.status {
            case AS_TIMEOUT:
                self = .timeOut
            case AS_NOT_FOUND:
                self = .notFound
            case AS_ILLEGAL_VALUE:
                self = .illegalValue
            default:
                if let _ = accountSettings.outgoing, let _ = accountSettings.incoming {
                    return nil
                } else {
                    self = .notFound
                }
            }
        }
    }
}

extension AccountSettings.AccountSettingsError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .timeOut:
            return NSLocalizedString("Account detection timed out",
                                     comment: "Error description detecting account settings")
        case .notFound, .illegalValue:
            return NSLocalizedString("Could not find servers. Please enter manually",
                                     comment: "Error description detecting account settings")
        }
    }
}
