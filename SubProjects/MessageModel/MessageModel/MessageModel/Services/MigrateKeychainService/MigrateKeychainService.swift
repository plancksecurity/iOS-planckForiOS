//
//  MigrateKeychainService.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 22.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation

import pEp4iosIntern

/// Service to migrate passwords, certificates from the default keychain
/// to either the keychain group `kSharedKeychain` or another one,
/// specified in the constructor.
class MigrateKeychainService: OperationBasedService {
    let keychainGroupTarget: String

    /// - parameter keychainGroupTarget: The name of the target keychain
    /// (where to migrate to), `kSharedKeychain` by default.
    init(keychainGroupTarget: String = kSharedKeychain) {
        self.keychainGroupTarget = keychainGroupTarget
    }

    override func operations() -> [Operation] {
        return []
    }
}
