//
//  GrandOperatorTests.swift
//  pEpForiOS
//
//  Created by Dirk Zimmermann on 26/04/16.
//  Copyright © 2016 p≡p Security S.A. All rights reserved.
//

import XCTest
import CoreData

import pEpForiOS

class GrandOperatorTests: XCTestCase {
    let comp = "GrandOperatorTests"

    let waitTime: NSTimeInterval = 10

    let correct = TestData.connectInfo
    var coreDataUtil: InMemoryCoreDataUtil!
    var connectionManager: ConnectionManager!
    var grandOperator: IGrandOperator!

    override func setUp() {
        super.setUp()
        coreDataUtil = InMemoryCoreDataUtil()
        connectionManager = ConnectionManager.init()
        grandOperator = GrandOperator.init(
            connectionManager: connectionManager, coreDataUtil: coreDataUtil)
    }
    
    /**
     Proof of concept for using managed object context in unit tests.
     */
    func testNewMessage() {
        let message = NSEntityDescription.insertNewObjectForEntityForName(
            Message.entityName(),
            inManagedObjectContext: coreDataUtil.managedObjectContext) as? Message
        XCTAssertNotNil(message)
        message!.subject = "Subject"
        XCTAssertNotNil(message?.subject)
    }

    func testVerifyConnectionAllFailed() {
        let exp = expectationWithDescription("verified")
        let connectionInfo = ConnectInfo.init(
            email: "none", imapPassword: "none", imapAuthMethod: .Login,
            smtpAuthMethod: .Plain,
            imapServerName: "cant.connect", imapServerPort: 993, imapTransport: .Plain,
            smtpServerName: "cant.connect", smtpServerPort: 516, smtpTransport: .TLS)
        grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            XCTAssertTrue(error!.code == Constants.NetworkError.Timeout.rawValue)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testVerifyConnectionImapAuthenticationFailed() {
        let exp = expectationWithDescription("verified")
        let connectionInfo = ConnectInfo.init(
            email: correct.email, imapPassword: "notwork", imapAuthMethod: correct.imapAuthMethod,
            smtpAuthMethod: correct.smtpAuthMethod,
            imapServerName: correct.imapServerName, imapServerPort: correct.imapServerPort,
            imapTransport: correct.imapTransport,
            smtpServerName: correct.smtpServerName, smtpServerPort: correct.smtpServerPort,
            smtpTransport: correct.smtpTransport)
        grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            XCTAssertEqual(error!.code, Constants.NetworkError.AuthenticationFailed.rawValue)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testVerifyConnectionSmtpAuthenticationFailed() {
        let exp = expectationWithDescription("verified")
        let connectionInfo = ConnectInfo.init(
            email: correct.email, imapUsername: correct.getImapUsername(),
            smtpUsername: correct.getSmtpUsername(), imapPassword: correct.imapPassword,
            smtpPassword: "wrong", imapAuthMethod: correct.imapAuthMethod,
            smtpAuthMethod: correct.smtpAuthMethod, imapServerName: correct.imapServerName,
            imapServerPort: correct.imapServerPort, imapTransport: correct.imapTransport,
            smtpServerName: correct.smtpServerName, smtpServerPort: correct.smtpServerPort,
            smtpTransport: correct.smtpTransport)
        grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testVerifyConnectionImapConnectionFailed() {
        let exp = expectationWithDescription("verified")
        let connectionInfo = ConnectInfo.init(
            email: correct.email, imapUsername: correct.getImapUsername(),
            smtpUsername: correct.getSmtpUsername(), imapPassword: correct.imapPassword,
            smtpPassword: correct.getSmtpPassword(), imapAuthMethod: correct.imapAuthMethod,
            smtpAuthMethod: correct.smtpAuthMethod, imapServerName: "noconnect",
            imapServerPort: correct.imapServerPort, imapTransport: correct.imapTransport,
            smtpServerName: correct.smtpServerName, smtpServerPort: correct.smtpServerPort,
            smtpTransport: correct.smtpTransport)
        grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testVerifyConnectionSmtpConnectionFailed() {
        let exp = expectationWithDescription("verified")
        let connectionInfo = ConnectInfo.init(
            email: correct.email, imapUsername: correct.getImapUsername(),
            smtpUsername: correct.getSmtpUsername(), imapPassword: correct.imapPassword,
            smtpPassword: correct.getSmtpPassword(), imapAuthMethod: correct.imapAuthMethod,
            smtpAuthMethod: correct.smtpAuthMethod, imapServerName: correct.imapServerName,
            imapServerPort: correct.imapServerPort, imapTransport: correct.imapTransport,
            smtpServerName: "noconnect", smtpServerPort: correct.smtpServerPort,
            smtpTransport: correct.smtpTransport)
        grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testVerifyConnectionOk() {
        let exp = expectationWithDescription("verified")
        grandOperator.verifyConnection(correct, completionBlock: { error in
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }
}
