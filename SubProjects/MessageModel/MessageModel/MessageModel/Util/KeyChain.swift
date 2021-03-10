//
//  KeyChain.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 14/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

import pEp4iosIntern
import pEpIOSToolbox

 /// Abstracts KeyChain ralted issues
class KeyChain {
    typealias Success = Bool
    static private let defaultServerType = "Server"
}

// MARK: - Passphrase For New Keys

extension KeyChain {
    private static let keyPassphrase = "security.pep.KeyChain.keyPassphrase"

    static func storePassphraseForNewKeys(_ passphrase: String) {
        add(key: keyPassphrase, password: passphrase)
    }

    static var passphraseForNewKeys: String? {
        return password(key: keyPassphrase)
    }

    static func deletePassphraseForNewKeys() {
        delete(key: keyPassphrase)
    }
}

// MARK: - Account Passwords

///Wraps saving account passwords into the keychain.
extension KeyChain {
    /// Get a password for a given key from the system keychain.
    ///
    /// - Parameter key: key to get the password for
    /// - Returns:  if the key exists in keychain: password for the given key
    ///             nil otherwize
    static func password(key: String) -> String? {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecMatchCaseInsensitive as String: kCFBooleanTrue as Any,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecAttrService as String: defaultServerType,
            kSecAttrAccount as String: key] as [String : Any]

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

    /// Updates, creates or deletes a password to/from the keychain.
    ///
    /// If you call this method with password != nil:
    ///        - if it already exists in the keychain: the password gets updated
    ///        - Otherwize:  a new entry is created in the keychain.
    ///
    /// If you call it with password == nil:
    ///        - if it already exists in the keychain: the password gets deleted from the keychain
    ///        - Otherwize: nothing is done.
    ///
    /// - Parameters:
    ///   - password: password to create/update. Set to nil to delete a password for a given key
    ///   - key: key to create/update/delete the password for
    /// - Returns: true if no error(s) occured, false otherwize
    @discardableResult static func updateCreateOrDelete(password: String?,
                                                               forKey key: String) -> Success {
        var success = false

        guard let existing = KeyChain.password(key: key) else {
                // No entry in KeyChain yet.
                // Create
                if password != nil {
                    success = KeyChain.add(key: key,
                                 serverType: defaultServerType,
                                 password: password)
                }
                return success
        }
        if password != nil && password != existing {
            // The password has changed.
            // Update
            success = KeyChain.update(key: key, newPassword: password)
        }  else if password == nil {
            // The password has been deleted.
            // Delete
            success = KeyChain.delete(key: key)
        }
        return success
    }
}

// MARK: - Private

extension KeyChain {

    @discardableResult static private func add(key: String,
                                               serverType: String = defaultServerType,
                                               password: String?) -> Success {
        guard let pass = password else {
            // No password, so nothing need to be done. Give a warning though.
            let warn = "Cannot add nil password. Key: \(key), serverType: \(serverType)"
            Log.shared.warn("%@", warn)
            return false
        }
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String,
            kSecAttrService as String: serverType,
            kSecAttrAccount as String: key,
            kSecValueData as String: pass.data(using: String.Encoding.utf8)!,
            kSecAttrAccessGroup as String: appGroupIdentifier] as [String : Any]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != noErr {
            let warn = "Could not save password for \(key), status \(status)"
            Log.shared.warn("%@", warn)
            return false
        }
        return true
    }

    @discardableResult static private func update(key: String, newPassword: String?) -> Success {
        guard let password = newPassword,
            let passwordData = password.data(using: String.Encoding.utf8) else {
                let warn = "Cannot update nil password. Key: \(key)"
                Log.shared.warn("%@", warn)
                return false
        }

        let updateQuery = [kSecValueData as String:passwordData] as [String : Any]

        let searchQuery = [kSecClass as String:kSecClassGenericPassword as String,
                           kSecAttrAccount as String:key,
                           kSecAttrAccessGroup as String: appGroupIdentifier]
        let status = SecItemUpdate(searchQuery as CFDictionary, updateQuery as CFDictionary)
        guard status == noErr else {
            let warn = "Could not update password for \(key), status \(status)"
            Log.shared.warn("%@", warn)
            return false
        }
        return true
    }

    @discardableResult static private func delete(key: String) -> Success {
        let deleteQuery = [kSecClass as String:kSecClassGenericPassword as String,
                           kSecAttrAccount as String:key,
                           kSecAttrAccessGroup as String: appGroupIdentifier]
        let status = SecItemDelete(deleteQuery as CFDictionary)
        if status != noErr {
            let warn = "Could not delete password for \(key), status \(status)"
            Log.shared.warn("%@", warn)
            return false
        } else {
            return true
        }
    }
}
