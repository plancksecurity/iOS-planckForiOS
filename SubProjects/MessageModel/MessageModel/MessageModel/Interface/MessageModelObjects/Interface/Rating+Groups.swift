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

    public func isTrusted() -> Bool {
        return [.trusted, .trustedAndAnonymized, .fullyAnonymous].contains(self)
    }

    public func isReliable() -> Bool {
        return [.reliable].contains(self)
    }
    
    public func isDangerous() -> Bool {
        return [.mistrust, .underAttack].contains(self)
    }
    
    public func isUnreliable() -> Bool {
        return [.cannotDecrypt, .haveNoKey, .unencrypted, .unreliable, .mediaKeyEncryption, .b0rken].contains(self)
    }
    
    public func isUndefined() -> Bool {
        return [.undefined].contains(self)
    }
}
