//
//  KeyChain+Extensions.swift
//  MessageModel
//
//  Created by Andreas Buff on 05.03.18.
//  Copyright © 2018 pEp Security S.A. All rights reserved.
//

import Foundation

extension KeyChain {
    static func serverPassword(forKey key: String) -> String? {
        return KeyChain.password(key: key)
    }
}
