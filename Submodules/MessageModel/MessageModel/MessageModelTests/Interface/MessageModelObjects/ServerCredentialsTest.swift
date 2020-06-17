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

    func testUpdatePassword() {
        let servers1 = cdAccount.servers?.allObjects as? [CdServer] ?? []

        guard let server1 = servers1.first else {
            XCTFail("No server")
            return
        }

        guard let testCredentials1 = server1.credentials else {
            XCTFail("No server credentials")
            return
        }

        guard let key = testCredentials1.key else {
            XCTFail("No key")
            return
        }
        // Assure Passowrd is setup correctly
        XCTAssertNotNil(key)
        let passBefore = testCredentials1.password
        XCTAssertNotNil(passBefore)
        let keychainPasswordBefore = KeyChain.password(key: key)
        XCTAssertNotNil(keychainPasswordBefore, "No password for key")
        XCTAssertEqual(passBefore, keychainPasswordBefore)
        // Update password ...
        let newPass = "newPass"
        testCredentials1.password = newPass

        moc.saveAndLogErrors()

        let servers2 = cdAccount.servers?.allObjects as? [CdServer] ?? []

        guard let server2 = servers2.first else {
            XCTFail("No server")
            return
        }

        guard let testCredentials2 = server2.credentials else {
            XCTFail("No server credentials")
            return
        }

        // ... and assure it has been updated in Core Data, Message Model and KeyChain correctly.
        XCTAssertNotNil(testCredentials2.key)
        XCTAssertEqual(testCredentials2.key, key)

        guard let keyAfter = testCredentials2.key else {
            XCTFail("No key")
            return
        }
        XCTAssertEqual(keyAfter, key, "Key must not change")

        let keychainPasswordAfter = KeyChain.password(key: key)
        XCTAssertNotNil(keychainPasswordAfter)
        XCTAssertEqual(keychainPasswordAfter, newPass)
    }
}
