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

    override func tearDown() {
        persistentSetup = nil
        TestUtil.waitForConnectionShutdown()
        XCTAssertEqual(Service.refCounter.refCount, 0)
        super.tearDown()
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
        let msg = persistentSetup.model.insertNewMessage() as! Message
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
