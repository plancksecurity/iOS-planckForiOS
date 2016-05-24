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
    var persistentSetup: PersistentSetup!

    override func setUp() {
        super.setUp()
        persistentSetup = PersistentSetup.init()
    }
    
    /**
     Proof of concept for using managed object context in unit tests.
     */
    func testNewMessage() {
        let message = NSEntityDescription.insertNewObjectForEntityForName(
            Message.entityName(),
            inManagedObjectContext:
            persistentSetup.grandOperator.coreDataUtil.managedObjectContext) as? Message
        XCTAssertNotNil(message)
        message!.subject = "Subject"
        XCTAssertNotNil(message?.subject)
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
    }

    func testFetchFolders() {
        let exp = expectationWithDescription("foldersFetched")
        persistentSetup.grandOperator.fetchFolders(correct, completionBlock: { error in
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            let p = NSPredicate.init(value: true)
            XCTAssertGreaterThan(self.persistentSetup.grandOperator.operationModel().folderCountByPredicate(p), 0)
            XCTAssertEqual(self.persistentSetup.grandOperator.operationModel().folderByName(
                ImapSync.defaultImapInboxName, email: self.correct.email)?.name.lowercaseString,
                ImapSync.defaultImapInboxName.lowercaseString)
        })
    }

    func testFetchMail() {
        let theUID = 10
        let exp = expectationWithDescription("mailFetched")
        persistentSetup.grandOperator.fetchMailFromFolderNamed(
            persistentSetup.connectionInfo,
            folderName: ImapSync.defaultImapInboxName, uid: theUID, completionBlock: { error in
                XCTAssertNil(error)
                exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
            let p = NSPredicate.init(value: true)
            XCTAssertGreaterThan(
                self.persistentSetup.grandOperator.operationModel().messageCountByPredicate(p), 0)
            let mail = self.persistentSetup.grandOperator.operationModel().messageByPredicate(
                NSPredicate.init(format: "uid = %d", theUID))
            XCTAssertNotNil(mail)
            XCTAssertEqual(mail?.uid, theUID)
        })
    }

    func createMail() -> Message {
        var msg = persistentSetup.model.insertNewMessage() as! Message
        msg.subject = "Subject"
        msg.longMessage = "Message body"
        let from = persistentSetup.model.insertOrUpdateContactEmail(
            "test001@peptest.ch", name: "Test 001") as! Contact
        msg.from = from
        let to = persistentSetup.model.insertOrUpdateContactEmail(
            "test002@peptest.ch", name: "Test 002") as! Contact
        msg.addToObject(to)
        return msg
    }

    func testSendMail() {
        let msg = createMail()
        let exp = expectationWithDescription("mailFetched")
        persistentSetup.grandOperator.sendMail(msg, completionBlock: { error in
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testSaveDraft() {
        let msg = createMail()
        let exp = expectationWithDescription("draftSaved")
        persistentSetup.grandOperator.sendMail(msg, completionBlock: { error in
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }
}
