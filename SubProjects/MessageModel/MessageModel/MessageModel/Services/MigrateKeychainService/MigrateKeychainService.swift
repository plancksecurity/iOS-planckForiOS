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
/// Runs exactly once after calling `start()`
class MigrateKeychainService: OperationBasedService {
    private let keychainGroupSource: String
    private let keychainGroupTarget: String
    private let completionBlock: (()->())?

    /// - parameter keychainGroupSource: The name of the source keychain  (where to migrate from)
    /// - parameter keychainGroupTarget: The name of the target keychain (where to migrate to),
    /// `kSharedKeychain` by default.
    /// - parameter backgroundTaskManager: custom backgroundTaskManager can be passed here
    /// - parameter completionBlock: called when the service is done
    init(keychainGroupSource: String,
         keychainGroupTarget: String = kSharedKeychain,
         backgroundTaskManager: BackgroundTaskManagerProtocol? = nil,
         completionBlock: (()->())? = nil) {
        self.keychainGroupSource = keychainGroupSource
        self.keychainGroupTarget = keychainGroupTarget
        self.completionBlock = completionBlock
        super.init(runOnce: true, backgroundTaskManager: backgroundTaskManager)
    }

    override func operations() -> [Operation] {
        let migrationOP = MigrateKeychainOperation(keychainGroupSource: keychainGroupSource,
                                                   keychainGroupTarget: keychainGroupTarget)
        migrationOP.completionBlock = { [weak self] in
            guard let me = self else {
                Log.shared.errorAndCrash("Lost myself")
                return
            }
            me.completionBlock?()
        }

        return [migrationOP]
    }
}
