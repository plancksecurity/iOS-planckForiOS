//
//  ServerCredentialsTest.swift
//  MessageModelTests
//
//  Created by Andreas Buff on 10.01.18.
//  Copyright © 2018 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel

class ServerCredentialsTest: PersistentStoreDrivenTestBase {

    // MARK: - Password, Key and KeyChain

    //!!!: Test fails due to an Xcode 9 Bug. See: IOS-733
    // Uncomment after Apple has fixed the issue.
    func testUpdatePassword() {
        let servers1 = cdAccount.servers?.allObjects as? [CdServer] ?? []

        guard let server = servers1.first else {
            XCTFail("No server")
            return
        }

        guard let testCredetials = server.credentials else {
            XCTFail("No server credentials")
            return
        }

        guard let key = testCredetials.key else {
            XCTFail("No key")
            return
        }
        // Assure Passowrd is setup correctly
        XCTAssertNotNil(key)
        let passBefore = testCredetials.password
        XCTAssertNotNil(passBefore)
        let keychainPasswordBefore = KeyChain.password(key: key)
        XCTAssertNotNil(keychainPasswordBefore, "No password for key")
        XCTAssertEqual(passBefore, keychainPasswordBefore)
        // Update password ...
        let newPass = "newPass"
        testCredetials.password = newPass
        account.session.commit()
        // ... and assure it has been updated in Core Data, Message Model and KeyChain correctly.
        XCTAssertNotNil(testCredetials.key)
        XCTAssertEqual(testCredetials.key, key)
        guard let server2 = account.servers?.first else {
            XCTFail("No server")
            return
        }
        let testCredetials2 = server2.credentials
        guard let keyAfter = testCredetials2.key else {
            XCTFail("No key")
            return
        }
        XCTAssertEqual(keyAfter, key, "Key must not change")

        let keychainPasswordAfter = KeyChain.password(key: key)
        XCTAssertNotNil(keychainPasswordAfter)
        XCTAssertEqual(keychainPasswordAfter, newPass)
    }
}
