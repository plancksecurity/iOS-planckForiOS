//
//  FetchMessagesServiceTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 05.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel
@testable import pEpForiOS

class FetchMessagesServiceTests: XCTestCase {
    var persistentSetup: PersistentSetup!

    var cdAccount: CdAccount!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup()

        let cdAccount = TestData().createWorkingCdAccount()
        cdAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount
    }

    override func tearDown() {
        persistentSetup = nil
    }

    func testFetchFinishesStrictly() {
        TestUtil.runFetchTest(
            parentName: #function, testCase: self, cdAccount: cdAccount,
            useDisfunctionalAccount: false,
            folderName: "inBOX", expectError: false)

        persistentSetup = nil

        // If there are still stray operations for storing messages,
        // the test will fail in the next couple of seconds.
        sleep(UInt32(TestUtil.waitTimeCoupleOfSeconds))
    }

    func testBasicFetchOK() {
        TestUtil.runFetchTest(
            parentName: #function, testCase: self, cdAccount: cdAccount,
            useDisfunctionalAccount: false,
            folderName: "inBOX", expectError: false)
    }

    func testBasicFetchAccountError() {
        TestUtil.runFetchTest(
            parentName: #function, testCase: self, cdAccount: cdAccount,
            useDisfunctionalAccount: true,
            folderName: "inBOX", expectError: true)
    }

    func testBasicFetchError() {
        TestUtil.runFetchTest(
            parentName: #function, testCase: self, cdAccount: cdAccount,
            useDisfunctionalAccount: false,
            folderName: "inBOXeZZZZ", expectError: true)
    }
}
