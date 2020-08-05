//
//  KeySyncHandshakeResult+PEPSyncHandshakeResult.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 05.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

extension KeySyncHandshakeResult {
    private init(pEpSyncHandshakeResult: PEPSyncHandshakeResult) {
        switch pEpSyncHandshakeResult {
        case .accepted: self = .accepted
        case .cancel: self = .cancel
        case .rejected: self = .rejected
        }
    }
}
