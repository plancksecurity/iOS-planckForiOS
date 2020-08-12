//
//  MessageRating+pEp.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

import PEPObjCAdapterFramework

extension MessageRating {
    static func from(pEpRating: PEPRating) -> MessageRating {
        switch pEpRating {
        case .b0rken:
            return .b0rken
        case .cannotDecrypt:
            return .cannotDecrypt
        case .fullyAnonymous:
            return .fullyAnonymous
        case .haveNoKey:
            return .haveNoKey
        case .mistrust:
            return .mistrust
        case .reliable:
            return .reliable
        case .trusted:
            return .trusted
        case .trustedAndAnonymized:
            return .trustedAndAnonymized
        case .undefined:
            return .undefined
        case .underAttack:
            return .underAttack
        case .unencrypted:
            return .unencrypted
        case .unreliable:
            return .unreliable
        }
    }
}
