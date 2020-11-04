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
        let transport_security_text = "Transport security (ConnectionTransport)"
        switch self {
        case .plain:
            return NSLocalizedString("None", comment: transport_security_text)
        case .TLS:
            return NSLocalizedString("SSL/TLS", comment: transport_security_text)
        case .startTLS:
            return NSLocalizedString("StartTLS", comment: transport_security_text)
        @unknown default:
            Log.shared.errorAndCrash("Unhandled case")
            return NSLocalizedString("None", comment: transport_security_text)
        }
    }
}
