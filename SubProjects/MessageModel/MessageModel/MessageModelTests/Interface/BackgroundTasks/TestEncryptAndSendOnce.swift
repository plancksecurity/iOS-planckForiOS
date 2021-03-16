//
//  TestEncryptAndSendOnce.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 16.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel

class TestEncryptAndSendOnce: PersistentStoreDrivenTestBase {
    func testNothingToSend() throws {
        let sender: EncryptAndSendOnceProtocol = EncryptAndSendOnce()

        let expHaveRun = expectation(description: "expHaveRun")

        sender.sendAllOutstandingMessages() { error in
            XCTAssertNil(error)
            expHaveRun.fulfill()
        }

        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testNothingToSendAndCancel() throws {
        let sender: EncryptAndSendOnceProtocol = EncryptAndSendOnce()

        let expHaveRun = expectation(description: "expHaveRun")

        sender.sendAllOutstandingMessages() { error in
            XCTAssertNil(error)
            expHaveRun.fulfill()
        }

        sender.cancel()

        waitForExpectations(timeout: TestUtil.waitTime)
    }
}
