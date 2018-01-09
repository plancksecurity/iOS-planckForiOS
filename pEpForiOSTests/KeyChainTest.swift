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

    func testStore() {
        let pass = "0001"
        let key = String(RAND_MAX%32)
        let server = "1"
        XCTAssertEqual(true, KeyChain.add(key: key, serverType: server , password: pass))
        XCTAssertEqual(pass, KeyChain.password(key: key, serverType: server))
    }

    func testUpdate() {
        let pass = "0001"
        let key = String(RAND_MAX%32)
        let server = "1"
        XCTAssertEqual(true, KeyChain.add(key: key, serverType: server , password: pass))
        XCTAssertEqual(pass, KeyChain.password(key: key, serverType: server))
        let newpass = "0002"
        XCTAssertEqual(true, KeyChain.update(key: key, newPassword: newpass))
        XCTAssertEqual(newpass, KeyChain.password(key: key, serverType: server))
    }

    func testDelete() {
        let pass = "0001"
        let key = String(RAND_MAX%32)
        let server = "1"
        XCTAssertEqual(true, KeyChain.add(key: key, serverType: server , password: pass))
        XCTAssertEqual(pass, KeyChain.password(key: key, serverType: server))
        XCTAssertEqual(true, KeyChain.delete(key: key))
        XCTAssertEqual(nil, KeyChain.password(key: key, serverType: server))
    }
}
