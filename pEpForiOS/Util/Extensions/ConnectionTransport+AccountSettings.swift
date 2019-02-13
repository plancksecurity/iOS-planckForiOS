//
//  ConnectionTransport+AccountSettings.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 07.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import Foundation
import pEpIOSToolbox

extension ConnectionTransport {
    init(accountSettingsTransport: AccountSettingsServerTransport) {
        switch accountSettingsTransport {
        case .plain: self = .plain
        case .startTLS: self = .startTLS
        case .TLS: self = .TLS
        case .unknown:
            Logger.utilLogger.errorAndCrash(
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
            case 143:
                self = .plain
            default:
                self = .TLS
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
