//
//  AccountSettingsError.swift
//  pEp
//
//  Created by Dirk Zimmermann on 26.02.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

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
