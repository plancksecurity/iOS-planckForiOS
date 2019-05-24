//
//  FakeNotifyHandshakeDelegate.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 21.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

/// Implementation of `PEPNotifyHandshakeDelegate` that always returns `.OK`.
/// - Note: Will be replaced by a real UI-implementation in the app. (TODO).
class FakeNotifyHandshakeDelegate: NSObject {
}

extension FakeNotifyHandshakeDelegate: PEPNotifyHandshakeDelegate {
    func notifyHandshake(_ object: UnsafeMutableRawPointer?,
                         me: PEPIdentity,
                         partner: PEPIdentity,
                         signal: PEPSyncHandshakeSignal) -> PEPStatus {
        return .OK
    }
}
