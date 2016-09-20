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

        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        let p = NSPredicate.init(value: true)
        let model = self.persistentSetup.model
        XCTAssertGreaterThan(
            model.folderCountByPredicate(p), 0)
        XCTAssertEqual(model.folderByName(
            ImapSync.defaultImapInboxName, email: self.correct.email)?.name.lowercaseString,
                       ImapSync.defaultImapInboxName.lowercaseString)
    }

    func createMail() -> Message {
        let msg = persistentSetup.model.insertNewMessage() as! Message
        msg.subject = "Subject"
        msg.longMessage = "Message body"
        let from = persistentSetup.model.insertOrUpdateContactEmail(
            "unittest.ios.4@peptest.ch", name: "UnitTestiOS 4") as! Contact
        msg.from = from
        let to = persistentSetup.model.insertOrUpdateContactEmail(
            "unittest.ios.3@peptest.ch", name: "UnitTestiOS 3") as! Contact
        msg.addToObject(to)
        return msg
    }

    func testChainFolderFetching() {
        let account = persistentSetup.model.insertAccountFromConnectInfo(
            persistentSetup.connectionInfo)
        var callbackNumber = 0
        let op1 = CreateLocalSpecialFoldersOperation.init(
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
            accountEmail: account.email)
        let op2 = FetchFoldersOperation.init(
            connectInfo: persistentSetup.connectionInfo,
            coreDataUtil: persistentSetup.grandOperator.coreDataUtil,
            connectionManager: persistentSetup.grandOperator.connectionManager)
        let expFoldersFetched = expectationWithDescription("expFoldersFetched")
        persistentSetup.grandOperator.chainOperations(
            [op1, op2],
            completionBlock: { error in
                XCTAssertNil(error)
                XCTAssertEqual(callbackNumber, 0)
                callbackNumber += 1
                expFoldersFetched.fulfill()
        })
        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            if let folders = self.persistentSetup.model.foldersByPredicate(
                NSPredicate.init(value: true), sortDescriptors: nil) {
                XCTAssertGreaterThan(folders.count, FolderType.allValuesToCreate.count)
            } else {
                XCTAssertTrue(false, "Expected folders created")
            }
            let folder = self.persistentSetup.model.folderByType(
                FolderType.Inbox, email: self.persistentSetup.connectionInfo.email)
            XCTAssertNotNil(folder)
        })
    }

    func createSpecialFolders(account: IAccount) {
        let expSpecialFoldersCreated = expectationWithDescription("expSpecialFoldersCreated")
        persistentSetup.grandOperator.createSpecialLocalFolders(
            account.email, completionBlock: { error in
                XCTAssertNil(error)
                expSpecialFoldersCreated.fulfill()
        })

        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testSendMail() {
        testFetchFolders()

        guard let account = persistentSetup.model.insertAccountFromConnectInfo(
            TestData.connectInfo) as? Account else {
                XCTAssertTrue(false)
                return
        }

        createSpecialFolders(account)

        guard let outFolder = persistentSetup.model.folderByType(
            .LocalOutbox, email:account.email) else {
                XCTAssertTrue(false)
                return
        }
        XCTAssertEqual(outFolder.messages.count, 0)

        let msg = createMail()
        let exp = expectationWithDescription("mailSent")
        persistentSetup.grandOperator.sendMail(msg, account: account, completionBlock: { error in
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
        XCTAssertEqual(outFolder.messages.count, 0)
    }

    func testSendMailFail() {
        testFetchFolders()

        guard let account = persistentSetup.model.insertAccountFromConnectInfo(
            TestData.connectInfoWrongPassword) as? Account else {
                XCTAssertTrue(false)
                return
        }

        createSpecialFolders(account)

        guard let outFolder = persistentSetup.model.folderByType(
            .LocalOutbox, email:account.email) else {
                XCTAssertTrue(false)
                return
        }
        XCTAssertEqual(outFolder.messages.count, 0)

        let msg = createMail()
        let exp = expectationWithDescription("mailSent")
        persistentSetup.grandOperator.sendMail(msg, account: account, completionBlock: { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        })
        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertEqual(outFolder.messages.count, 1)
    }

    func testSaveDraft() {
        guard let account = persistentSetup.model.insertAccountFromConnectInfo(
            TestData.connectInfo) as? Account else {
                XCTAssertTrue(false)
                return
        }

        let expFoldersFetched = expectationWithDescription("foldersFetched")
        persistentSetup.grandOperator.fetchFolders(correct, completionBlock: { error in
            XCTAssertNil(error)
            expFoldersFetched.fulfill()
        })
        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        guard let draftsFolder = persistentSetup.model.folderByType(
            .Drafts, email: account.email) else {
                XCTAssertTrue(false)
                return
        }

        let expDraftsFetched = expectationWithDescription("expDraftsFetched")
        persistentSetup.grandOperator.fetchEmailsAndDecryptConnectInfos(
            [account.connectInfo], folderName: draftsFolder.name, completionBlock: { error in
                XCTAssertNil(error)
                expDraftsFetched.fulfill()
        })
        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        let numDrafts = draftsFolder.messages.count

        let msg = createMail()
        let expDraftSaved = expectationWithDescription("expDraftSaved")
        persistentSetup.grandOperator.saveDraftMail(
            msg, account: account, completionBlock: { error in
                XCTAssertNil(error)
                expDraftSaved.fulfill()
        })
        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        let expDraftsFetched2 = expectationWithDescription("expDraftsFetched2")
        persistentSetup.grandOperator.fetchEmailsAndDecryptConnectInfos(
            [account.connectInfo], folderName: draftsFolder.name, completionBlock: { error in
                XCTAssertNil(error)
                expDraftsFetched2.fulfill()
        })
        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertGreaterThan(draftsFolder.messages.count, numDrafts)
    }

    func testSyncFlags() {
        let emailsFetched = expectationWithDescription("emailsFetched")
        persistentSetup.grandOperator.fetchEmailsAndDecryptConnectInfos(
            [persistentSetup.connectionInfo], folderName: nil, completionBlock: { error in
                XCTAssertNil(error)
                emailsFetched.fulfill()
        })
        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        guard let inbox = persistentSetup.model.folderByType(
            .Inbox, email: persistentSetup.accountEmail) else {
                XCTAssertTrue(false)
                return
        }

        var expectations = [XCTestExpectation]()
        var counter = 0
        for elm in inbox.messages {
            guard let m = elm as? IMessage else {
                XCTAssertTrue(false)
                break
            }
            m.flagFlagged = NSNumber.init(bool: !m.flagFlagged.boolValue)
            m.updateFlags()

            let exp = expectationWithDescription("flagsSynced\(counter)")
            expectations.append(exp)
            counter += 1
            persistentSetup.grandOperator.syncFlagsToServerForFolder(
                m.folder, completionBlock: { error in
                    XCTAssertNil(error)
                    exp.fulfill()
            })
        }
        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testDeleteFolder() {
        let expFoldersFetched = expectationWithDescription("expFoldersFetched")
        persistentSetup.grandOperator.fetchFolders(
        persistentSetup.account.connectInfo) { error in
            XCTAssertNil(error)
            expFoldersFetched.fulfill()
        }
        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        let expFolderCreated = expectationWithDescription("expFolderCreated")
        persistentSetup.grandOperator.createFolderOfType(
        persistentSetup.account, folderType: .Drafts) { error in
            XCTAssertNil(error)
            expFolderCreated.fulfill()
        }
        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        guard let draftsFolder = persistentSetup.model.folderByType(
            .Drafts, email: persistentSetup.accountEmail) else {
                XCTAssertTrue(false)
                return
        }

        let expFolderDeleted = expectationWithDescription("expFolderDeleted")
        persistentSetup.grandOperator.deleteFolder( draftsFolder) { error in
            XCTAssertNil(error)
            expFolderDeleted.fulfill()
        }
        waitForExpectationsWithTimeout(TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertNil(persistentSetup.model.folderByType(.Drafts,
            email: persistentSetup.accountEmail))
    }
}