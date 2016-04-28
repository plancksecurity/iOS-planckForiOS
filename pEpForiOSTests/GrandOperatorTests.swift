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

    let correct = TestData()
    var coreDataUtil: InMemoryCoreDataUtil!
    var connectionManager: ConnectionManager!
    var grandOperator: IGrandOperator!

    override func setUp() {
        super.setUp()
        coreDataUtil = InMemoryCoreDataUtil()
        connectionManager = ConnectionManager.init(coreDataUtil: coreDataUtil)
        grandOperator = GrandOperator.init(connectionManager: connectionManager,
                                           coreDataUtil: coreDataUtil)
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

    /*
    func testVerifyConnectionAllFailed() {
        var failed = false
        let connectionInfo = ConnectInfo.init(
            email: "none", imapPassword: "none", imapAuthMethod: "none", smtpAuthMethod: "none",
            imapServerName: "cant.connect", imapServerPort: 993, imapTransport: .Plain,
            smtpServerName: "cant.connect", smtpServerPort: 516, smtpTransport: .TLS)
        grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            failed = true
        })
        TestUtil.runloopFor(5, until: {
            return failed
        })
        XCTAssertTrue(failed)
    }

    func testVerifyConnectionImapAuthenticationFailed() {
        var failed = false
        let connectionInfo = ConnectInfo.init(
            email: correct.email, imapPassword: "notwork", imapAuthMethod: correct.imapAuthMethod,
            smtpAuthMethod: correct.smtpAuthMethod,
            imapServerName: correct.imapServerName, imapServerPort: correct.imapServerPort,
            imapTransport: correct.imapTransport,
            smtpServerName: correct.smtpServerName, smtpServerPort: correct.smtpServerPort,
            smtpTransport: correct.smtpTransport)
        grandOperator.verifyConnection(connectionInfo, completionBlock: { error in
            XCTAssertNotNil(error)
            failed = true
        })
        TestUtil.runloopFor(5, until: {
            return failed
        })
        XCTAssertTrue(failed)
    }

    func testVerifyConnectionSmtpAuthenticationFailed() {
        var failed = false
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
            failed = true
        })
        TestUtil.runloopFor(5, until: {
            return failed
        })
        XCTAssertTrue(failed)
    }

    func testVerifyConnectionImapConnectionFailed() {
        var failed = false
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
            failed = true
        })
        TestUtil.runloopFor(5, until: {
            return failed
        })
        XCTAssertTrue(failed)
    }

    func testVerifyConnectionSmtpConnectionFailed() {
        var failed = false
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
            failed = true
        })
        TestUtil.runloopFor(5, until: {
            return failed
        })
        XCTAssertTrue(failed)
    }

    func testVerifyConnectionOk() {
        var success = false
        grandOperator.verifyConnection(correct, completionBlock: { error in
            XCTAssertNil(error)
            success = true
        })
        TestUtil.runloopFor(5, until: {
            return success
        })
        XCTAssertTrue(success)
    }
*/}
