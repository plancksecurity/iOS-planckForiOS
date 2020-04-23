//
//  CoreDataDrivenTestBase.swift
//  pEpForiOS
//
//  Created by buff on 26.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel //FIXME:
import PEPObjCAdapterFramework

open class CoreDataDrivenTestBase: XCTestCase {
    var account: Account!

    var session: PEPSession {
        return PEPSession()
    }

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
