//
//  Keychain+TestUtils.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 25.04.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import MessageModel

extension KeyChain {

    // Returns the total number of kechain items that are accessable.
    // The total number of item should never be > numAccounts * 2 (IMAP+SMTP)
    static func numKeychainItems(testCase: XCTestCase) -> Int {
        let secItemClasses = [kSecClassGenericPassword,
                              kSecClassInternetPassword,
                              kSecClassCertificate,
                              kSecClassKey,
                              kSecClassIdentity]
        var numTotalItems = 0
        for secItemClass in secItemClasses {
            let query: [String:Any] = [kSecClass as String : secItemClass,
                                       kSecReturnData as String  : kCFBooleanTrue,
                                       kSecReturnAttributes as String : kCFBooleanTrue,
                                       kSecReturnRef as String : kCFBooleanTrue,
                                       kSecMatchLimit as String : kSecMatchLimitAll]
            var result: AnyObject?
            let lastResultCode = withUnsafeMutablePointer(to: &result) {
                SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
            }

            var values = [String:String]()
            guard lastResultCode == noErr else {
                print("Error in class \(secItemClass): \(lastResultCode)")
                continue
            }
            guard let array = result as? Array<Dictionary<String, Any>> else {
                XCTFail("Error casting")
                continue
            }
            numTotalItems += array.count
            for item in array {
                guard let key = item[kSecAttrAccount as String] as? String,
                    let value = item[kSecValueData as String] as? Data else {
                        XCTFail("Error casting")
                        continue
                }
                values[key] = String(data: value, encoding:.utf8)
            }
//            print("values in class \(secItemClass): \(values)")
        }
//        print("numTotalItems: \(numTotalItems)")
        return numTotalItems
    }
}
