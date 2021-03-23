//
//  MigrateKeychainOperation.swift
//  MessageModel
//
//  Created by Dirk Zimmermann on 22.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import Foundation

import pEp4iosIntern
import pEpIOSToolbox

/// Operation to migrate passwords, certificates from the default keychain
/// to either the keychain group `kSharedKeychain` or another one,
/// specified in the constructor.
/// Used by `MigrateKeychainService`.
class MigrateKeychainOperation: ConcurrentBaseOperation {
    let keychainGroupTarget: String
    let queue: DispatchQueue

    /// - parameter keychainGroupTarget: The name of the target keychain
    /// (where to migrate to), `kSharedKeychain` by default.
    init(keychainGroupTarget: String = kSharedKeychain) {
        self.keychainGroupTarget = keychainGroupTarget
        self.queue = DispatchQueue(label: "MigrateKeychainOperationQueue")
    }

    override func main() {
        queue.async { [weak self] in
            guard let me = self else {
                // could happen, don't interpret that as an error
                return
            }
            me.migrate()
            me.markAsFinished()
        }
    }

    // MARK: - Private

    private func migrate() {
        let query: [String : Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecReturnAttributes as String: kCFBooleanTrue as Any,
            kSecAttrService as String: KeyChain.defaultServerType,
            kSecMatchLimit as String: kSecMatchLimitAll]

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        if status != noErr {
            let warn = "Could not enumerate keychain items, status \(status)"
            Log.shared.warn("%@", warn)
        }

        guard let theResults = result as? [[String:AnyObject]] else {
            Log.shared.logWarn(message: "Cannot cast to [[String:AnyObject]]")
            return
        }

        for dict in theResults {
            print("*** \(dict)")
        }
    }
}
