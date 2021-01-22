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
import PEPObjCAdapterTypes_iOS
import PEPObjCAdapter_iOS // Only for the tear down

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
        PEPSession.cleanup()
        XCTAssertTrue(PEPUtils.pEpClean())
        super.tearDown()
    }
}
