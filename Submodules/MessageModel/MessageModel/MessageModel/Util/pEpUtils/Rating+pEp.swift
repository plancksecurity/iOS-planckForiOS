//
//  Rating+pEp.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 12.08.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation

extension Rating {
    init(pEpRating: PEPRating) {
        switch pEpRating {
        case .b0rken:
            self = .b0rken
        case .cannotDecrypt:
            self = .cannotDecrypt
        case .fullyAnonymous:
            self = .fullyAnonymous
        case .haveNoKey:
            self = .haveNoKey
        case .mistrust:
            self = .mistrust
        case .reliable:
            self = .reliable
        case .trusted:
            self = .trusted
        case .trustedAndAnonymized:
            self = .trustedAndAnonymized
        case .undefined:
            self = .undefined
        case .underAttack:
            self = .underAttack
        case .unencrypted:
            self = .unencrypted
        case .unreliable:
            self = .unreliable
        }
    }

    func pEpRating() -> PEPRating {
        switch self {
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

    func toString() -> String {
        return PEPSession().string(from: pEpRating())
    }
}
