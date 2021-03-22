//
//  MigrateKeychainService.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 22.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation

import pEp4iosIntern

class MigrateKeychainService: OperationBasedService {
    let keychainGroupTarget: String

    init(keychainGroupTarget: String = kSharedKeychain) {
        self.keychainGroupTarget = keychainGroupTarget
    }

    override func operations() -> [Operation] {
        return []
    }
}
