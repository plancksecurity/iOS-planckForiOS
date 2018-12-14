//
//  LogTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 13.12.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest
import os.log

@testable import pEpForiOS
@testable import MessageModel

class LogTest: XCTestCase {
    func testSimple() {
        zlog("%d %@", 1, "zlog blah")
        zlog(message: "zlog message")
        if #available(iOS 10.0, macOS 10.12, tvOS 10.0, watchOS 3.0, *) {
            os_log("%d %@", 1, "direct blah")
        }
    }
}
