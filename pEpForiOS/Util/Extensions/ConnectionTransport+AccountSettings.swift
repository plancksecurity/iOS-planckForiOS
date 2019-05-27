//
//  ConnectionTransport+AccountSettings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox
import PantomimeFramework

extension ConnectionTransport {
    init(accountSettingsTransport: AccountSettingsServerTransport) {
        switch accountSettingsTransport {
        case .startTLS: self = .startTLS
        case .TLS: self = .TLS
        case .unknown:
            Log.shared.errorAndCrash(
                "Unsupported LAS transport: %d", accountSettingsTransport.rawValue)
            self = .plain
        }
    }

    /**
     If the IMAP transport is unknown, tries to figure out the default for this port.
     */
    init(accountSettingsTransport: AccountSettingsServerTransport, imapPort: Int) {
        switch accountSettingsTransport {
        case .unknown:
            switch imapPort {
            case 993:
                self = .TLS // we do not support plaintext passwords over insecure connections
            default:
                self = .startTLS
            }
        default:
            self = ConnectionTransport(accountSettingsTransport: accountSettingsTransport)
        }
    }

    /**
     If the SMTP transport is unknown, tries to figure out the default for this port.
     */
    init(accountSettingsTransport: AccountSettingsServerTransport, smtpPort: Int) {
        switch accountSettingsTransport {
        case .unknown:
            switch smtpPort {
            case 465:
                self = .TLS
            default:
                self = .startTLS
            }
        default:
            self = ConnectionTransport(accountSettingsTransport: accountSettingsTransport)
        }
    }
}
