//
//  AccountDrivenTestBase.swift
//  pEpForiOS
//
//  Created by buff on 26.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel //FIXME:

/// Base class for tests that need an account set up.
open class AccountDrivenTestBase: XCTestCase {
    var account: Account!

    override open func setUp() {
        super.setUp()
        Stack.shared.reset() //!!!: this should not be required. Rm after all tests use a propper base class!
        self.account = TestData().createWorkingAccount()
    }

    override open func tearDown() {
        Stack.shared.reset()
        XCTAssertTrue(PEPUtils.pEpClean())
        super.tearDown()
    }

    func testDummyTest() {
        // Does nothing.
        // Background: Due to the substring "Test" in the name of this class (or inheriting from XCTestCase, not sure), Xcode considers it a test, but it never gets green as it holds no signle test that is run.
        // That causes the complete pEp4iOS test suite to never be green (but grey) in success case. Thus we run this dummy test.
    }
}
