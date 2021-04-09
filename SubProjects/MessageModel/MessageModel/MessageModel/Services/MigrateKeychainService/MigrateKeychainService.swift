//
//  MigrateKeychainService.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 22.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation

import pEpIOSToolbox
import pEp4iosIntern

/// Service to migrate passwords, certificates from the default keychain
/// to either the keychain group `kSharedKeychain` or another one,
/// specified in the constructor.
/// - Note: Is only supposed to run once during app execution, which is configured
/// in the constructor.
class MigrateKeychainService: OperationBasedService {
    let keychainGroupSource: String
    let keychainGroupTarget: String

    /// - parameter keychainGroupTarget: The name of the target keychain
    /// (where to migrate to), `kSharedKeychain` by default.
    init(keychainGroupSource: String,
         keychainGroupTarget: String = kSharedKeychain,
         backgroundTaskManager: BackgroundTaskManagerProtocol? = nil) {
        self.keychainGroupSource = keychainGroupSource
        self.keychainGroupTarget = keychainGroupTarget
        super.init(runOnce: true, backgroundTaskManager: backgroundTaskManager)
    }

    override func operations() -> [Operation] {
        return [MigrateKeychainOperation(keychainGroupSource: keychainGroupSource,
                                         keychainGroupTarget: keychainGroupTarget)]
    }
}
