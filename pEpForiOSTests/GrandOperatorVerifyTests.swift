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

    let correct = TestData.connectInfo
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup.init()
    }

    override func tearDown() {
        persistentSetup = nil
        super.tearDown()
    }

    /**
     Verifies that background operations get cleaned up after execution in a background queue.
     */
    func testSimpleBackgroundOperation() {
        class BackgroundOp: Operation {
            let expRun: XCTestExpectation
            let expDeinit: XCTestExpectation

            init(expRun: XCTestExpectation, expDeinit: XCTestExpectation) {
                self.expRun = expRun
                self.expDeinit = expDeinit
            }

            override func main() {
                expRun.fulfill()
            }

            deinit {
                expDeinit.fulfill()
            }
        }
        let expRun = expectation(description: "run")
        let expDeinit = expectation(description: "deinit")

        let queue = OperationQueue.init()
        queue.addOperation(BackgroundOp.init(expRun: expRun, expDeinit: expDeinit))

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testVerifyConnectionAllFailed() {
        let exp = expectation(description: "verified")
        let connectionInfo = ConnectInfo.init(
            nameOfTheUser: "The User",
            email: "none", imapPassword: "none",
            imapServerName: "cant.connect", imapServerPort: 993, imapTransport: .plain,
            smtpServerName: "cant.connect", smtpServerPort: 516, smtpTransport: .TLS)
        persistentSetup.grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            XCTAssertTrue(error?.code == Constants.NetworkError.timeout.rawValue)
            exp.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testVerifyConnectionImapAuthenticationFailed() {
        let exp = expectation(description: "verified")
        let connectionInfo = ConnectInfo.init(
            nameOfTheUser: "The User",
            email: correct.email, imapPassword: "notwork",
            imapServerName: correct.imapServerName, imapServerPort: correct.imapServerPort,
            imapTransport: correct.imapTransport,
            smtpServerName: correct.smtpServerName, smtpServerPort: correct.smtpServerPort,
            smtpTransport: correct.smtpTransport)
        persistentSetup.grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, Constants.NetworkError.authenticationFailed.rawValue)
            exp.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testVerifyConnectionSmtpAuthenticationFailed() {
        let exp = expectation(description: "verified")
        var connectionInfo = correct
        connectionInfo.smtpPassword = "WRONG!"
        persistentSetup.grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testVerifyConnectionImapConnectionFailed() {
        let exp = expectation(description: "verifyIMAPFailed")
        var connectionInfo = correct
        connectionInfo.imapServerName = "noconnect"
        persistentSetup.grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testVerifyConnectionSmtpConnectionFailed() {
        let exp = expectation(description: "verifySMTPFailed")
        var connectionInfo = correct
        connectionInfo.smtpServerName = "noconnect"
        persistentSetup.grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testVerifyConnectionOk() {
        let exp = expectation(description: "verifyConnectionOK")
        persistentSetup.grandOperator.verifyConnection(correct, completionBlock: { error in
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }
}
