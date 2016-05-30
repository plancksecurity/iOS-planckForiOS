//
//  TestUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest

class TestUtil {
    static func waitForConnectionShutdown() {
        for _ in 1...5 {
            if CWTCPConnection.numberOfRunningConnections() == 0 {
                break
            }
            NSThread.sleepForTimeInterval(0.2)
        }
        XCTAssertEqual(CWTCPConnection.numberOfRunningConnections(), 0)
    }
}