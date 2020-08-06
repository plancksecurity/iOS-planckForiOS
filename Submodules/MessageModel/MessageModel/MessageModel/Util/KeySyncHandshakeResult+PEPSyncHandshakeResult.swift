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
    func pEpSyncHandshakeResult() -> PEPSyncHandshakeResult {
        switch self {
        case .accepted: return .accepted
        case .cancel: return .cancel
        case .rejected: return .rejected
        }
    }
}
