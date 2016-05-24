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
public class KeyChain {
    static let comp = "KeyChain"

    static func addEmail(email: String, serverType: String, password: String?) -> Bool {
        if let pass = password {
            let query = [
                kSecClass as String: kSecClassGenericPassword as String,
                kSecAttrService as String: serverType,
                kSecAttrAccount as String: email,
                kSecValueData as String: pass.dataUsingEncoding(NSUTF8StringEncoding)!]

            SecItemDelete(query)

            let status = SecItemAdd(query, nil)
            if status != noErr {
                Log.warn(comp, "Could not save password for \(email)")
                return false
            }
            return true
        } else {
            // no password, so nothing need to be done
            return false
        }
    }

    static func getPassword(email: String, serverType: String) -> String? {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecMatchCaseInsensitive as String: kCFBooleanTrue,
            kSecReturnData as String: kCFBooleanTrue,
            kSecAttrService as String: serverType,
            kSecAttrAccount as String: email]
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        if status != noErr {
            Log.warn(comp, "Could not get password for \(email)")
        }
        if result != nil {
            let str = String.init(data: result as! NSData, encoding: NSUTF8StringEncoding)
            return str
        } else {
            Log.warn(comp, "No password found for \(email)")
            return nil
        }
    }

}