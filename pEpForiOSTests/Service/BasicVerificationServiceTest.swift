//
//  BasicVerificationServiceTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 12.04.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest

import MessageModel

class BasicVerificationServiceTestDelegate: BasicVerificationServiceDelegate {
    private let expectation: XCTestExpectation
    public var error: Error?

    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }

    func verified(connectInfo: BasicConnectInfo, error: Error?,
                  service: BasicVerificationServiceProtocol) {
        self.error = error
        expectation.fulfill()
    }
}

class BasicVerificationServiceTest: XCTestCase {
    override func setUp() {
    }

    override func tearDown() {
    }

    func test(service: inout BasicVerificationServiceProtocol,
              connectInfo: BasicConnectInfo,
              verify: (Error?) -> ()) {
        let expVerificationDone = expectation(description: "expVerificationDone")
        let myDelegate = BasicVerificationServiceTestDelegate(expectation: expVerificationDone)
        service.delegate = myDelegate
        service.verify(connectInfo: connectInfo)
        wait(for: [expVerificationDone], timeout: TestUtil.waitTime)
        verify(myDelegate.error)
    }
}
