//
//  LogTest.swift
//  MessageModelTests
//
//  Created by Andreas Buff on 01.03.19.
//  Copyright © 2019 pEp Security S.A. All rights reserved.
//

import XCTest

import pEpIOSToolbox

@testable import MessageModel

class LogTest: XCTestCase {

    func testSharedNotNil() {
        XCTAssertNotNil(Log.shared)
    }
}
