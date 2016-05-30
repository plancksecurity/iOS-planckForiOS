//
//  TestUtil.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 30/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation
import XCTest

import pEpForiOS

class TestUtil {
    static let connectonShutDownWaitTime: NSTimeInterval = 1
    static let numberOfTriesConnectonShutDown = 5

    /**
     Waits and verifies that all connection threads are finished.
     */
    static func waitForConnectionShutdown() {
        for _ in 1...numberOfTriesConnectonShutDown {
            if CWTCPConnection.numberOfRunningConnections() == 0 {
                break
            }
            NSThread.sleepForTimeInterval(connectonShutDownWaitTime)
        }
        XCTAssertEqual(CWTCPConnection.numberOfRunningConnections(), 0)
    }

    /**
     Waits and verifies that all service objects (IMAP, SMTP) are finished.
     */
    static func waitForServiceCleanup() {
        for _ in 1...numberOfTriesConnectonShutDown {
            if Service.refCounter.refCount == 0 {
                break
            }
            NSThread.sleepForTimeInterval(connectonShutDownWaitTime)
        }
        XCTAssertEqual(Service.refCounter.refCount, 0)
    }

    /**
     Waits and verifies that all service objects are properly shutdown and cleaned up.
     */
    static func waitForServiceShutdown() {
        TestUtil.waitForConnectionShutdown()
        TestUtil.waitForServiceCleanup()
    }
}