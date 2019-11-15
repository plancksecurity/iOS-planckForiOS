//
//  Classes.swift
//  MacCatalystEvaluation
//
//  Created by Andreas Buff on 14.11.19.
//  Copyright © 2019 pEp. All rights reserved.
//

import Foundation


// MARK: - KeyChain

public class KeyChain {
    public typealias Success = Bool
    static private let defaultServerType = "Server"

    static public func password(key: String) -> String? {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecMatchCaseInsensitive as String: kCFBooleanTrue!,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecAttrService as String: defaultServerType,
            kSecAttrAccount as String: key] as [String : Any]

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        if status != noErr {
            return nil
        }

        guard let r = result as? Data else {
            return nil
        }
        let str = String(data: r, encoding: String.Encoding.utf8)
        return str
    }

    static public func add(key: String, password: String) -> Success {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String,
            kSecAttrService as String: defaultServerType,
            kSecAttrAccount as String: key,
            kSecValueData as String: password.data(using: String.Encoding.utf8)!] as [String : Any]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != noErr {
            return false
        }
        return true
    }
}
