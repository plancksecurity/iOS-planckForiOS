//
//  NotifyHandshakeDelegate.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 21.05.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

class NotifyHandshakeDelegate: NSObject {}

extension NotifyHandshakeDelegate: PEPNotifyHandshakeDelegate {
    func notifyHandshake(_ object: UnsafeMutableRawPointer?,
                         me: PEPIdentity,
                         partner: PEPIdentity,
                         signal: PEPSyncHandshakeSignal) -> PEPStatus {
        return .OK
    }
}
