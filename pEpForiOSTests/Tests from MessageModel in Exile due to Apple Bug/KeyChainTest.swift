//
//  KeyChainTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 20.09.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel

/*
 This belongs to MessageModelTests, but has been moved here due an Apple bug.
 See: IOS-733
 */
class KeyChainTest: XCTestCase {
    let pass = "0001"
    var numItemsBefore = 0
    var numAdded = 0

    override func setUp() {
        super.setUp()
        numItemsBefore = KeyChain.numKeychainItems(testCase: self)
        numAdded = 0
    }

    func testStore() {
        let key = UUID().uuidString
        numAdded += 1
        XCTAssertTrue(KeyChain.updateCreateOrDelete(password: pass, forKey: key))
        XCTAssertEqual(pass, KeyChain.password(key: key))
        XCTAssertTrue(isCorrectTotalNumberOfKeychainItems())
    }

    func testUpdate() {
        let key = UUID().uuidString
        // Save password
        numAdded += 1
        XCTAssertTrue(KeyChain.updateCreateOrDelete(password: pass, forKey: key))
        // Assure it has been saved
        XCTAssertEqual(pass, KeyChain.password(key: key))
        // Update password
        let newpass = "0002"
        XCTAssertTrue(KeyChain.updateCreateOrDelete(password: newpass, forKey: key))
        // Assure it has been updates
        XCTAssertEqual(newpass, KeyChain.password(key: key),
                       "Password has been updated")
        XCTAssertTrue(isCorrectTotalNumberOfKeychainItems())
    }

    func testDelete() {
        let key = UUID().uuidString
        // Save password
        numAdded += 1
        XCTAssertTrue(KeyChain.updateCreateOrDelete(password: pass, forKey: key))
        // Assure it has been saved
        XCTAssertEqual(pass, KeyChain.password(key: key))
        // Delete Password
        numAdded -= 1
        XCTAssertTrue(KeyChain.updateCreateOrDelete(password: nil, forKey: key))
        // Assure it has been deleted
        XCTAssertNil(KeyChain.password(key: key))
        XCTAssertTrue(isCorrectTotalNumberOfKeychainItems())
    }

    private func isCorrectTotalNumberOfKeychainItems() -> Bool {
        let expected = numItemsBefore + numAdded
        let actual = KeyChain.numKeychainItems(testCase: self)
        return actual == expected
    }
}
