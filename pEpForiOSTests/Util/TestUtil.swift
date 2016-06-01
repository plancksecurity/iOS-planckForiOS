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

    static var initialNumberOfRunningConnections = 0
    static var initialNumberOfServices = 0

    /**
     In case there are other connections open, call this function before relying on
     `waitForConnectionShutdown` or `waitForServiceCleanup`
     */
    static func adjustBaseLevel() {
        initialNumberOfRunningConnections = CWTCPConnection.numberOfRunningConnections()
        initialNumberOfServices = Service.refCounter.refCount
    }

    /**
     Waits and verifies that all connection threads are finished.
     */
    static func waitForConnectionShutdown() {
        for _ in 1...numberOfTriesConnectonShutDown {
            if CWTCPConnection.numberOfRunningConnections() == initialNumberOfRunningConnections {
                break
            }
            NSThread.sleepForTimeInterval(connectonShutDownWaitTime)
        }
        XCTAssertEqual(CWTCPConnection.numberOfRunningConnections(),
                       initialNumberOfRunningConnections)
    }

    /**
     Waits and verifies that all service objects (IMAP, SMTP) are finished.
     */
    static func waitForServiceCleanup() {
        for _ in 1...numberOfTriesConnectonShutDown {
            if Service.refCounter.refCount == initialNumberOfServices {
                break
            }
            NSThread.sleepForTimeInterval(connectonShutDownWaitTime)
        }
        XCTAssertEqual(Service.refCounter.refCount, initialNumberOfServices)
    }

    /**
     Waits and verifies that all service objects are properly shutdown and cleaned up.
     */
    static func waitForServiceShutdown() {
        TestUtil.waitForConnectionShutdown()
        TestUtil.waitForServiceCleanup()
    }
}