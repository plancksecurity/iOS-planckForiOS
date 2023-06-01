//
//  Rating+Colors.swift
//  MessageModel
//
//  Created by Martin Brude on 1/6/23.
//  Copyright © 2023 pEp Security S.A. All rights reserved.
//

import Foundation
import PEPObjCAdapter

extension Rating {

    public func isGreen() -> Bool {
        return [Rating.trusted, Rating.trustedAndAnonymized, Rating.fullyAnonymous].contains(self)
    }

    public func isYellow() -> Bool {
        return [Rating.reliable].contains(self)
    }
    
    public func isRed() -> Bool {
        return [Rating.mistrust, .underAttack].contains(self)
    }
    
    public func isNoColor() -> Bool {
        return [Rating.cannotDecrypt, .haveNoKey, .unencrypted, .unreliable, .mediaKeyEncryption, .b0rken].contains(self)
    }
}
