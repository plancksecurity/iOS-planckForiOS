//
//  GrandOperatorVerifyTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

import pEpForiOS

/**
 A collection of connection verification tests, where you can rely on all connections being
 closed in the end (due to the one-way nature of testing a connection).
 */
class GrandOperatorVerifyTests: XCTestCase {
    let comp = "GrandOperatorVerifyTests"

    let waitTime: NSTimeInterval = 10
    let connectonShutDownWaitTime: NSTimeInterval = 1
    let numberOfTriesConnectonShutDown = 5
    var numberOfOpenTCPConnections = 0

    let correct = TestData.connectInfo
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup.init()
        numberOfOpenTCPConnections = CWTCPConnection.numberOfRunningConnections()
    }

    func testVerifyConnectionAllFailed() {
        let exp = expectationWithDescription("verified")
        let connectionInfo = ConnectInfo.init(
            email: "none", imapPassword: "none",
            imapServerName: "cant.connect", imapServerPort: 993, imapTransport: .Plain,
            smtpServerName: "cant.connect", smtpServerPort: 516, smtpTransport: .TLS)
        persistentSetup.grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            XCTAssertTrue(error!.code == Constants.NetworkError.Timeout.rawValue)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
        self.waitForConnectionShutdown()
    }

    func testVerifyConnectionImapAuthenticationFailed() {
        let exp = expectationWithDescription("verified")
        let connectionInfo = ConnectInfo.init(
            email: correct.email, imapPassword: "notwork",
            imapServerName: correct.imapServerName, imapServerPort: correct.imapServerPort,
            imapTransport: correct.imapTransport,
            smtpServerName: correct.smtpServerName, smtpServerPort: correct.smtpServerPort,
            smtpTransport: correct.smtpTransport)
        persistentSetup.grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, Constants.NetworkError.AuthenticationFailed.rawValue)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
        self.waitForConnectionShutdown()
    }

    func testVerifyConnectionSmtpAuthenticationFailed() {
        let exp = expectationWithDescription("verified")
        var connectionInfo = correct
        connectionInfo.smtpPassword = "WRONG!"
        persistentSetup.grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
        self.waitForConnectionShutdown()
    }

    func testVerifyConnectionImapConnectionFailed() {
        let exp = expectationWithDescription("verified")
        var connectionInfo = correct
        connectionInfo.imapServerName = "noconnect"
        persistentSetup.grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
        self.waitForConnectionShutdown()
    }

    func testVerifyConnectionSmtpConnectionFailed() {
        let exp = expectationWithDescription("verified")
        var connectionInfo = correct
        connectionInfo.smtpServerName = "noconnect"
        persistentSetup.grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
        self.waitForConnectionShutdown()
    }

    func testVerifyConnectionOk() {
        let exp = expectationWithDescription("verified")
        persistentSetup.grandOperator.verifyConnection(correct, completionBlock: { error in
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
        self.waitForConnectionShutdown()
    }

    func waitForConnectionShutdown() {
        for _ in 1...self.numberOfTriesConnectonShutDown {
            if CWTCPConnection.numberOfRunningConnections() == numberOfOpenTCPConnections {
                break
            }
            NSThread.sleepForTimeInterval(self.connectonShutDownWaitTime)
        }
        XCTAssertEqual(CWTCPConnection.numberOfRunningConnections(), numberOfOpenTCPConnections)
    }
}
