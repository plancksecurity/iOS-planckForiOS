//
//  MigrateKeychainServiceTest.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 22.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel

class MigrateKeychainServiceTest: XCTestCase {
    override func setUpWithError() throws {
        setupKeychainItems()
    }

    func testOperation() throws {
        let expFinished = expectation(description: "expFinished")
        let op = MigrateKeychainOperation()
        op.completionBlock = {
            expFinished.fulfill()
        }
        op.start()
        waitForExpectations(timeout: TestUtil.waitTime)
    }

    // MARK: -- Private Helpers

    private func setupKeychainItems() {
    }
}
