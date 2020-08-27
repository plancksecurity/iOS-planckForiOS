//
//  Keychain+TestUtils.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 25.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel //!!!: move to MM

extension KeyChain {

    static private let allSecClasses = [kSecClassGenericPassword,
                                        kSecClassInternetPassword,
                                        kSecClassCertificate,
                                        kSecClassKey,
                                        kSecClassIdentity]

    /// Deletes all accessable items from the system keychain.
    static func deleteAllKeychainItems() {
        for secItemClass in allSecClasses {
            let query: [String:Any] = [kSecClass as String : secItemClass]
            SecItemDelete(query as CFDictionary)
        }
    }

    // Returns the total number of kechain items that are accessable.
    // The total number of item should never be > numAccounts * 2 (IMAP+SMTP)
    static func numKeychainItems() -> Int {
        var numTotalItems = 0
        for secItemClass in allSecClasses {
            let query: [String:Any] = [kSecClass as String : secItemClass,
                                       kSecReturnData as String  : kCFBooleanTrue,
                                       kSecReturnAttributes as String : kCFBooleanTrue,
                                       kSecReturnRef as String : kCFBooleanTrue,
                                       kSecMatchLimit as String : kSecMatchLimitAll]
            var result: AnyObject?
            let lastResultCode = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }
            guard lastResultCode == noErr else {
                // We get an error for every SecClass we never used. That's OK.
                continue
            }
            guard let array = result as? Array<Dictionary<String, Any>> else {
                XCTFail("Error casting")
                continue
            }
            numTotalItems += array.count
        }
        return numTotalItems
    }

    static func allKeychainItems(testCase: XCTestCase) -> [String:String] {
        var allItems = [String:String]()

        for secItemClass in allSecClasses {
            let query: [String:Any] = [kSecClass as String : secItemClass,
                                       kSecReturnData as String  : kCFBooleanTrue,
                                       kSecReturnAttributes as String : kCFBooleanTrue,
                                       kSecReturnRef as String : kCFBooleanTrue,
                                       kSecMatchLimit as String : kSecMatchLimitAll]
            var itemsForSecClass: AnyObject?
            let lastResultCode = withUnsafeMutablePointer(to: &itemsForSecClass) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }
            guard lastResultCode == noErr else {
                print("Error in class \(secItemClass): \(lastResultCode)")
                continue
            }
            guard let array = itemsForSecClass as? Array<Dictionary<String, Any>> else {
                XCTFail("Error casting")
                continue
            }
            for item in array {
                guard let key = item[kSecAttrAccount as String] as? String,
                    let value = item[kSecValueData as String] as? Data else {
                        XCTFail("Error casting")
                        continue
                }
                allItems[key] = String(data: value, encoding:.utf8)
            }
        }
        return allItems
    }
}
