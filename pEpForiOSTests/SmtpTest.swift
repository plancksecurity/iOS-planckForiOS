//
//  SmtpTest.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 04/05/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import Foundation

import XCTest
import CoreData

import pEpForiOS

class SmtpTest: XCTestCase {
    let waitTime: NSTimeInterval = 10

    func testSimpleAuth() {
        class MyDelegate: SmtpSendDefaultDelegate {
            var authenticatedExpectation: XCTestExpectation?
            override func authenticationCompleted(smtp: SmtpSend,
                                                  theNotification: NSNotification?) {
                authenticatedExpectation?.fulfill()
            }
        }
        let smtp = SmtpSend.init(connectInfo: TestData.connectInfo)
        let del = MyDelegate.init()
        del.authenticatedExpectation = expectationWithDescription("authenticatedExpectation")
        smtp.delegate = del
        smtp.start()
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            // Adapt this for different servers
            XCTAssertEqual(smtp.bestAuthMethod(), AuthMethod.Login)
            smtp.close()
        })
    }

    /*
    func testTriggerNil() {
        for _ in 0..<1000000000 {
            testSimpleAuth()
            waitForConnectionShutdown()
        }
    }

    func waitForConnectionShutdown() {
        for _ in 1...5 {
            if CWTCPConnection.numberOfRunningConnections() == 0 {
                break
            }
            NSThread.sleepForTimeInterval(0.2)
        }
        XCTAssertEqual(CWTCPConnection.numberOfRunningConnections(), 0)
    }
 */
}