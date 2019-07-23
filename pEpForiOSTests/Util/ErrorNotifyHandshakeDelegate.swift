//
//  ErrorNotifyHandshakeDelegate.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 03.06.19.
//  Copyright © 2019 p≡p Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

/// PEPNotifyHandshakeDelegate that produces an error when called.
class ErrorNotifyHandshakeDelegate: NSObject, PEPNotifyHandshakeDelegate {
    func notifyHandshake(_ object: UnsafeMutableRawPointer?,
                         me: PEPIdentity?,
                         partner: PEPIdentity?,
                         signal: PEPSyncHandshakeSignal) -> PEPStatus {
        return .unknownError
    }
}
