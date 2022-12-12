//
//  MockNotifyHandshakeDelegate.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 03.06.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapter

class MockNotifyHandshakeDelegate: NSObject {
}

extension MockNotifyHandshakeDelegate: PEPNotifyHandshakeDelegate {
    func notifyHandshake(_ object: UnsafeMutableRawPointer?,
                         me: PEPIdentity?,
                         partner: PEPIdentity?,
                         signal: PEPSyncHandshakeSignal) -> PEPStatus {
        return .OK
    }
}
