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

    func testStore() {
        let key = UUID().uuidString
        XCTAssertTrue(KeyChain.updateCreateOrDelete(password: pass, forKey: key))
        XCTAssertEqual(pass, KeyChain.password(key: key))
    }

    func testUpdate() {
        let key = UUID().uuidString
        // Save password
        XCTAssertTrue(KeyChain.updateCreateOrDelete(password: pass, forKey: key))
        // Assure it has been saved
        XCTAssertEqual(pass, KeyChain.password(key: key))
        // Update password
        let newpass = "0002"
        XCTAssertTrue(KeyChain.updateCreateOrDelete(password: newpass, forKey: key))
        // Assure it has been updates
        XCTAssertEqual(newpass, KeyChain.password(key: key),
                       "Password has been updated")
    }

    func testDelete() {
        let key = UUID().uuidString
        // Save password
        XCTAssertTrue(KeyChain.updateCreateOrDelete(password: pass, forKey: key))
        // Assure it has been saved
        XCTAssertEqual(pass, KeyChain.password(key: key))
        // Delete Pasword
        XCTAssertTrue(KeyChain.updateCreateOrDelete(password: nil, forKey: key))
        // Assure it has been deleted
        XCTAssertNil(KeyChain.password(key: key))
    }
}
