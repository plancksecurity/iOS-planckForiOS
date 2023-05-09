//
//  ConnectionTransport+LocalizedString.swift
//  pEp
//
//  Created by Dirk Zimmermann on 04.11.20.
//  Copyright © 2020 p≡p Security S.A. All rights reserved.
//

import Foundation

import PantomimeFramework
import pEpIOSToolbox

extension ConnectionTransport {
    public func localizedString() -> String {
        switch self {
        case .plain:
            return NSLocalizedString("None", comment: "No SSL or TLS (ConnectionTransport)")
        case .TLS:
            return NSLocalizedString("SSL/TLS", comment: "SSL/TLS (ConnectionTransport)")
        case .startTLS:
            return NSLocalizedString("StartTLS", comment: "StartTLS (ConnectionTransport)")
        @unknown default:
            Log.shared.errorAndCrash("Unhandled case")
            return NSLocalizedString("None", comment: "No SSL or TLS (ConnectionTransport)")
        }
    }
}
