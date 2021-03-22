//
//  MigrateKeychainServiceTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 22.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel

class MigrateKeychainServiceTest: XCTestCase {
    var keysAdded = [String:String]()

    override func setUpWithError() throws {
        setupKeychainItems()
    }

    func testOperation() throws {
        let expFinished = expectation(description: "expFinished")
        let op = MigrateKeychainOperation()
        op.completionBlock = {
            expFinished.fulfill()
        }
        op.start()
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    // MARK: -- Private Helpers

    static let defaultServerType = "Server"

    let defaultKeychainGroup = "security.MessageModelTestApp"
    let keychainTargetGroup = "security.test.MessageModelTestApp"

    private func setupKeychainItems() {
        for i in 1...50 {
            let theKey = "key_\(i)"
            let thePassword = "password_\(i)"
            add(key: theKey, password: thePassword)
            keysAdded[theKey] = thePassword
        }
    }

    private func basicPasswordQuery(key: String,
                                    password: String,
                                    serverType: String = MigrateKeychainServiceTest.defaultServerType) -> [String : Any] {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String,
            kSecAttrService as String: serverType,
            kSecAttrAccount as String: key,
            kSecValueData as String: password.data(using: String.Encoding.utf8)!] as [String : Any]

        return query
    }

    private func add(key: String,
                     password: String,
                     serverType: String = MigrateKeychainServiceTest.defaultServerType) {
        let query = basicPasswordQuery(key: key, password: password)

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != noErr {
            XCTFail()
        }
    }
}
