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

            me.migratePasswords()
            me.migrateCertificates()

            me.markAsFinished()
        }
    }

    // MARK: - Private

    private func migratePasswords() {
        let allTheKeys = genericPasswordKeys()

        for theKey in allTheKeys {
            guard let thePassword = KeyChain.password(key: theKey) else {
                Log.shared.logWarn(message: "Cannot get the password for \(theKey)")
                return
            }
            saveToTarget(key: theKey, password: thePassword)
        }
    }

    private func migrateCertificates() {
        let util = ClientCertificateUtil()

        let identityPairs = util.listExisting()

        for (uuidLabel, secIndentity) in identityPairs {
            let removeQuery: [CFString : Any] = [kSecAttrLabel: uuidLabel,
                                                 kSecValueRef: secIndentity]

            /*
            let removeStatus = SecItemDelete(removeQuery as CFDictionary)
            if removeStatus != errSecSuccess {
                Log.shared.logError(message: "Could not delete client certificate \(uuidLabel)")
            }
             */

            let addQuery: [CFString : Any] = [kSecReturnPersistentRef: true,
                                              kSecAttrLabel: uuidLabel,
                                              kSecValueRef: secIndentity,
                                              kSecAttrAccessGroup: keychainGroupTarget]

            var resultRef: CFTypeRef? = nil
            let identityStatus = SecItemAdd(addQuery as CFDictionary, &resultRef);
            if identityStatus != errSecSuccess {
                if identityStatus == errSecDuplicateItem {
                    Log.shared.logWarn(message: "Client certificate already exists: \(uuidLabel)")
                } else {
                    Log.shared.logError(message: "Could not migrate client certificate: \(uuidLabel)")
                }
            }
        }
    }

    private func saveToTarget(key: String, password: String) {
        guard let thePassword = password.data(using: String.Encoding.utf8) else {
            Log.shared.logWarn(message: "Could not create password data for \(key)")
            return
        }

        let queryAll: [String : Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String,
            kSecAttrService as String: KeyChain.defaultServerType,
            kSecAttrAccount as String: key,
            kSecValueData as String: thePassword]

        /*
        let statusDelete = SecItemDelete(queryAll as CFDictionary)
        if statusDelete != noErr {
            Log.shared.logWarn(message: "Could not delete (old) password for \(key), status \(statusDelete)")
        }
         */

        var queryTargetGroup = queryAll
        queryTargetGroup[kSecAttrAccessGroup as String] = keychainGroupTarget

        let status = SecItemAdd(queryTargetGroup as CFDictionary, nil)
        if status != noErr && status != errSecDuplicateItem {
            // -34018: errSecMissingEntitlement
            Log.shared.logWarn(message: "Could not save password for \(key), status \(status)")
        }
    }

    private func genericPasswordKeys(accessGroup: String? = nil) -> [String] {
        var query: [String : Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecReturnAttributes as String: kCFBooleanTrue as Any,
            kSecAttrService as String: KeyChain.defaultServerType,
            kSecMatchLimit as String: kSecMatchLimitAll]

        if let theAccessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = theAccessGroup
        }

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        if status != noErr {
            Log.shared.logWarn(message: "Could not enumerate keychain items, status \(status)")
        }

        guard let theResults = result as? [[String:AnyObject]] else {
            Log.shared.logWarn(message: "Cannot cast to [[String:AnyObject]]")
            return []
        }

        let keysAnyObject = theResults.map { $0["acct"] }

        guard let theKeys = keysAnyObject as? [String] else {
            Log.shared.logWarn(message: "The \"acct\" keychain key could not be cast to String")
            return []
        }

        return theKeys
    }
}