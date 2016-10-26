//
//  KeyChain.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 14/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

/**
 Wraps saving account passwords into the keychain.
 */
open class KeyChain {
    static let comp = "KeyChain"

    static func add(key: String, serverType: String, password: String?) -> Bool {
        if let pass = password {
            let query = [
                kSecClass as String: kSecClassGenericPassword as String,
                kSecAttrService as String: serverType,
                kSecAttrAccount as String: key,
                kSecValueData as String: pass.data(using: String.Encoding.utf8)!] as [String : Any]

            SecItemDelete(query as CFDictionary)

            let status = SecItemAdd(query as CFDictionary, nil)
            if status != noErr {
                Log.warnComponent(comp, "Could not save password for \(key)")
                return false
            }
            return true
        } else {
            // no password, so nothing need to be done
            return false
        }
    }

    static func password(key: String, serverType: String) -> String? {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecMatchCaseInsensitive as String: kCFBooleanTrue,
            kSecReturnData as String: kCFBooleanTrue,
            kSecAttrService as String: serverType,
            kSecAttrAccount as String: key] as [String : Any]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status != noErr {
            Log.warnComponent(comp, "Could not get password for \(key)")
        }
        if result != nil {
            let str = String.init(data: result as! Data, encoding: String.Encoding.utf8)
            return str
        } else {
            Log.warnComponent(comp, "No password found for \(key)")
            return nil
        }
    }

}
