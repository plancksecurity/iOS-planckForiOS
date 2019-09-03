//
//  ReportingErrorContainerTest.swift
//  pEpForiOSTests
//
//  Created by Andreas Buff on 30.11.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

@testable import pEpForiOS
@testable import MessageModel

extension ReportingErrorContainerTest {
    fileprivate class TestDelegate: ReportingErrorContainerDelegate {
        var delegateCalled = false
        func reportingErrorContainer(_ errorContainer: ReportingErrorContainer, didReceive error: Error) {
            delegateCalled = true
        }
    }
}

struct TestError: Error {}

class ReportingErrorContainerTest: XCTestCase {

    func testDelegation() {
        let error = TestError()
        let delegate = TestDelegate()
        let testee = ReportingErrorContainer(delegate: delegate)
        testee.addError(error)
        XCTAssertTrue(delegate.delegateCalled)
    }

    func testDelegation_multipleErrors() {
        let error = TestError()
        let delegate = TestDelegate()
        let testee = ReportingErrorContainer(delegate: delegate)
        testee.addError(error)
        XCTAssertTrue(delegate.delegateCalled)
        delegate.delegateCalled = false
        testee.addError(error)
        XCTAssertTrue(delegate.delegateCalled)
    }
}
