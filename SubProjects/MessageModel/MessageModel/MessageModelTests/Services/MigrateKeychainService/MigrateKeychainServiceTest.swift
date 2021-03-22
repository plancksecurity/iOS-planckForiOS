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

    let defaultKeychain = "security.MessageModelTestApp"

    private func setupKeychainItems() {
    }

    private func add(key: String, serverType: String = "Server", password: String) {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String,
            kSecAttrService as String: serverType,
            kSecAttrAccount as String: key,
            kSecValueData as String: password.data(using: String.Encoding.utf8)!] as [String : Any]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != noErr {
            XCTFail()
        }
    }
}
