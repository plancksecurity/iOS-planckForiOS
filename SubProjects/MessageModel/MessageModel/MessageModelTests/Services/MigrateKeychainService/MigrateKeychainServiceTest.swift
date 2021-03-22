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

        for i in 1...numberOfKeyPasswordPairs {
            query(key: key(index: i),
                  password: password(index: i))

            query(key: key(index: i),
                  password: password(index: i),
                  accessGroup: keychainTargetGroup)

            query(key: key(index: i),
                  password: password(index: i),
                  accessGroup: defaultKeychainGroup)
        }
    }

    override func tearDownWithError() throws {
        removeKeychainItems()
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

    let numberOfKeyPasswordPairs = 50

    let defaultKeychainGroup = "security.MessageModelTestApp"
    let keychainTargetGroup = "security.test.MessageModelTestApp"

    private func key(index: Int) -> String {
        return "key_\(index)"
    }

    private func password(index: Int) -> String {
        return "password\(index)"
    }

    private func setupKeychainItems() {
        for i in 1...numberOfKeyPasswordPairs {
            let theKey = key(index: i)
            let thePassword = password(index: i)
            add(key: theKey, password: thePassword)
            keysAdded[theKey] = thePassword
        }
    }

    private func removeKeychainItems() {
        for (key, password) in keysAdded {
            remove(key: key, password: password)
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
        let query = basicPasswordQuery(key: key, password: password, serverType: serverType)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != noErr {
            XCTFail()
        }
    }

    private func remove(key: String,
                        password: String,
                        serverType: String = MigrateKeychainServiceTest.defaultServerType) {
        let query = basicPasswordQuery(key: key, password: password, serverType: serverType)
        let status = SecItemDelete(query as CFDictionary)
        if status != noErr {
            XCTFail()
        }
    }

    private func query(key: String,
                       password: String,
                       accessGroup: String? = nil,
                       serverType: String = MigrateKeychainServiceTest.defaultServerType) {
        var query = basicPasswordQuery(key: key, password: password, serverType: serverType)

        query[kSecMatchCaseInsensitive as String] = kCFBooleanTrue as Any
        query[kSecReturnData as String] = kCFBooleanTrue as Any

        if let theGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = theGroup
        }

        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }

        if status != noErr {
            XCTFail("Could not copy \(key) from \(accessGroup ?? "nil"): \(status)")
            return
        }

        guard let r = result as? Data else {
            XCTFail()
            return
        }
        let str = String(data: r, encoding: String.Encoding.utf8)
        guard let theStr = str else {
            XCTFail()
            return
        }
        XCTAssertEqual(str, password, "key \(key) has \(theStr) stored, not the expected \(password)")
    }
}
