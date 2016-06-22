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
        TestUtil.adjustBaseLevel()
    }

    override func tearDown() {
        persistentSetup = nil
        TestUtil.waitForServiceShutdown()
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
            XCTAssertGreaterThan(
                self.persistentSetup.grandOperator.operationModel().folderCountByPredicate(p), 0)
            XCTAssertEqual(self.persistentSetup.grandOperator.operationModel().folderByName(
                ImapSync.defaultImapInboxName, email: self.correct.email)?.name.lowercaseString,
                ImapSync.defaultImapInboxName.lowercaseString)
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

    func testChainFolderFetching() {
        if let account = persistentSetup.model.insertAccountFromConnectInfo(
            persistentSetup.connectionInfo) {
            var callbackNumber = 0
            let op1 = CreateLocalSpecialFoldersOperation.init(
                grandOperator: persistentSetup.grandOperator, accountEmail: account.email)
            let op2 = FetchFoldersOperation.init(grandOperator: persistentSetup.grandOperator,
                                                 connectInfo: persistentSetup.connectionInfo)
            let expFoldersFetched = expectationWithDescription("expFoldersFetched")
            persistentSetup.grandOperator.chainOperations(
                [op1, op2],
                completionBlock: { error in
                    XCTAssertNil(error)
                    XCTAssertEqual(callbackNumber, 0)
                    callbackNumber += 1
                    expFoldersFetched.fulfill()
            })
            waitForExpectationsWithTimeout(waitTime, handler: { error in
                XCTAssertNil(error)
                if let folders = self.persistentSetup.model.foldersByPredicate(
                    NSPredicate.init(value: true), sortDescriptors: nil) {
                    XCTAssertGreaterThan(folders.count, FolderType.allValuesToCreate.count)
                } else {
                    XCTAssertTrue(false, "Expected folders created")
                }
                let folder = self.persistentSetup.model.folderInbox()
                XCTAssertNotNil(folder)
            })
        } else {
            XCTAssertTrue(false, "Expected account to be created")
        }
    }

    func testSendMail() {
        let account = persistentSetup.model.insertAccountFromConnectInfo(TestData.connectInfo)
            as? Account
        XCTAssertNotNil(account)
        let msg = createMail()
        let exp = expectationWithDescription("mailFetched")
        persistentSetup.grandOperator.sendMail(msg, account: account!, completionBlock: { error in
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testSaveDraft() {
        let account = persistentSetup.model.insertAccountFromConnectInfo(TestData.connectInfo)
            as? Account
        XCTAssertNotNil(account)
        let msg = createMail()
        let exp = expectationWithDescription("draftSaved")
        persistentSetup.grandOperator.sendMail(msg, account: account!, completionBlock: { error in
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }
}
