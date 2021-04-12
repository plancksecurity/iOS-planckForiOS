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
    let keychainGroupSource: String
    let keychainGroupTarget: String
    let queue: DispatchQueue

    /// - parameter keychainGroupTarget: The name of the target keychain
    /// (where to migrate to), `kSharedKeychain` by default.
    init(keychainGroupSource: String, keychainGroupTarget: String = kSharedKeychain) {
        self.keychainGroupSource = keychainGroupSource
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
        let allTheKeys = genericPasswordKeys(accessGroup: keychainGroupSource)

        for theKey in allTheKeys {
            guard let thePassword = password(key: theKey, accessGroup: keychainGroupSource) else {
                Log.shared.logWarn(message: "Cannot get the password for \(theKey)")
                return
            }
            saveToTargetAndDelete(key: theKey, password: thePassword)
        }
    }

    private func migrateCertificates() {
        let util = ClientCertificateUtil()

        let identityPairs = util.listExisting(accessGroup: keychainGroupSource)

        for (uuidLabel, secIndentity) in identityPairs {
            let removeQuery: [CFString : Any] = [kSecAttrLabel: uuidLabel,
                                                 kSecValueRef: secIndentity,
                                                 kSecAttrAccessGroup: keychainGroupSource]

            let removeStatus = SecItemDelete(removeQuery as CFDictionary)
            if removeStatus != errSecSuccess {
                Log.shared.logError(message: "Could not delete client certificate \(uuidLabel)")
            }

            var addQuery = removeQuery
            addQuery[kSecAttrAccessGroup] = keychainGroupTarget

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil);
            if addStatus != errSecSuccess {
                if addStatus == errSecDuplicateItem {
                    Log.shared.logWarn(message: "Client certificate already exists: \(uuidLabel)")
                } else {
                    Log.shared.logError(message: "Could not migrate client certificate: \(uuidLabel)")
                }
            }
        }
    }

    private func saveToTargetAndDelete(key: String, password: String) {
        guard let thePassword = password.data(using: String.Encoding.utf8) else {
            Log.shared.logWarn(message: "Could not create password data for \(key)")
            return
        }

        let queryAll: [String : Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String,
            kSecAttrService as String: KeyChain.defaultServerType,
            kSecAttrAccount as String: key,
            kSecValueData as String: thePassword,
            kSecAttrAccessGroup as String: keychainGroupSource]

        let statusDelete = SecItemDelete(queryAll as CFDictionary)
        if statusDelete != noErr {
            Log.shared.logWarn(message: "Could not delete (old) password for \(key), status \(statusDelete)")
        }

        var queryTargetGroup = queryAll
        queryTargetGroup[kSecAttrAccessGroup as String] = keychainGroupTarget

        let status = SecItemAdd(queryTargetGroup as CFDictionary, nil)
        if status != noErr && status != errSecDuplicateItem {
            Log.shared.logWarn(message: "Could not save password for \(key), status \(status)")
        }
    }

    func password(key: String, accessGroup: String) -> String? {
        let query: [String : Any] = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecMatchCaseInsensitive as String: kCFBooleanTrue as Any,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecAttrService as String: KeyChain.defaultServerType,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: accessGroup]

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        if status != noErr {
            let warn = "Could not get password for \(key), status \(status)"
            Log.shared.warn("%@", warn)
        }
        guard let r = result as? Data else {
            let warn = "No password found for \(key)"
            Log.shared.warn("%@", warn)
            return nil
        }
        let str = String(data: r, encoding: String.Encoding.utf8)
        return str
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
