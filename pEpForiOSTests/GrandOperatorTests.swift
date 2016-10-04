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
        let message = NSEntityDescription.insertNewObject(
            forEntityName: Message.entityName(),
            into:
            persistentSetup.grandOperator.coreDataUtil.managedObjectContext) as? Message
        XCTAssertNotNil(message)
        message!.subject = "Subject"
        XCTAssertNotNil(message?.subject)
    }

    func testFetchFolders() {
        let exp = expectation(description: "foldersFetched")
        persistentSetup.grandOperator.fetchFolders(
            persistentSetup.connectionInfo, completionBlock: { error in
                XCTAssertNil(error)
                exp.fulfill()
        })

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        let p = NSPredicate.init(value: true)
        let model = self.persistentSetup.model
        XCTAssertGreaterThan(
            model.folderCountByPredicate(p), 0)
        XCTAssertEqual(model.folderByType(
            .inbox, email: self.persistentSetup.accountEmail)?.name.lowercased(),
                       ImapSync.defaultImapInboxName.lowercased())
    }

    func createMail() -> Message {
        let msg = persistentSetup.model.insertNewMessage()
        msg.subject = "Subject"
        msg.longMessage = "Message body"
        let from = persistentSetup.model.insertOrUpdateContactEmail(
            persistentSetup.accountEmail, name: persistentSetup.accountEmail)
        msg.from = from
        let to = persistentSetup.model.insertOrUpdateContactEmail(
            "unittest.ios.3@peptest.ch", name: "UnitTestiOS 3")
        msg.addToObject(value: to)
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
        let expFoldersFetched = expectation(description: "expFoldersFetched")
        persistentSetup.grandOperator.chainOperations(
            [op1, op2],
            completionBlock: { error in
                XCTAssertNil(error)
                XCTAssertEqual(callbackNumber, 0)
                callbackNumber += 1
                expFoldersFetched.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            if let folders = self.persistentSetup.model.foldersByPredicate(
                NSPredicate.init(value: true), sortDescriptors: nil) {
                XCTAssertGreaterThan(folders.count, FolderType.allValuesToCreate.count)
            } else {
                XCTAssertTrue(false, "Expected folders created")
            }
            let folder = self.persistentSetup.model.folderByType(
                FolderType.inbox, email: self.persistentSetup.connectionInfo.email)
            XCTAssertNotNil(folder)
        })
    }

    func createSpecialFolders(_ account: Account) {
        let expSpecialFoldersCreated = expectation(description: "expSpecialFoldersCreated")
        persistentSetup.grandOperator.createSpecialLocalFolders(
            account.email, completionBlock: { error in
                XCTAssertNil(error)
                expSpecialFoldersCreated.fulfill()
        })

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testSendMail() {
        testFetchFolders()
        let account = persistentSetup.model.insertAccountFromConnectInfo(
            persistentSetup.connectionInfo)

        createSpecialFolders(account)

        guard let outFolder = persistentSetup.model.folderByType(
            .localOutbox, email:account.email) else {
                XCTAssertTrue(false)
                return
        }
        XCTAssertEqual(outFolder.messages.count, 0)

        let msg = createMail()
        let exp = expectation(description: "mailSent")
        persistentSetup.grandOperator.sendMail(msg, account: account, completionBlock: { error in
            XCTAssertNil(error)
            exp.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
        XCTAssertEqual(outFolder.messages.count, 0)
    }

    func testSendMailFail() {
        testFetchFolders()

        let account = persistentSetup.model.insertAccountFromConnectInfo(
            TestData.connectInfoWrongPassword)

        createSpecialFolders(account)

        guard let outFolder = persistentSetup.model.folderByType(
            .localOutbox, email:account.email) else {
                XCTAssertTrue(false)
                return
        }
        XCTAssertEqual(outFolder.messages.count, 0)

        let msg = createMail()
        let exp = expectation(description: "mailSent")
        persistentSetup.grandOperator.sendMail(msg, account: account, completionBlock: { error in
            XCTAssertNotNil(error)
            exp.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertEqual(outFolder.messages.count, 1)
    }

    func testSaveDraft() {
        let account = persistentSetup.model.insertAccountFromConnectInfo(
            TestData.connectInfo)

        let expFoldersFetched = expectation(description: "foldersFetched")
        persistentSetup.grandOperator.fetchFolders(correct, completionBlock: { error in
            XCTAssertNil(error)
            expFoldersFetched.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        guard let draftsFolder = persistentSetup.model.folderByType(
            .drafts, email: account.email) else {
                XCTAssertTrue(false)
                return
        }

        let expDraftsFetched = expectation(description: "expDraftsFetched")
        persistentSetup.grandOperator.fetchEmailsAndDecryptConnectInfos(
            [account.connectInfo], folderName: draftsFolder.name, completionBlock: { error in
                XCTAssertNil(error)
                expDraftsFetched.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        let numDrafts = draftsFolder.messages.count

        let msg = createMail()
        let expDraftSaved = expectation(description: "expDraftSaved")
        persistentSetup.grandOperator.saveDraftMail(
            msg, account: account, completionBlock: { error in
                XCTAssertNil(error)
                expDraftSaved.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        let expDraftsFetched2 = expectation(description: "expDraftsFetched2")
        persistentSetup.grandOperator.fetchEmailsAndDecryptConnectInfos(
            [account.connectInfo], folderName: draftsFolder.name, completionBlock: { error in
                XCTAssertNil(error)
                expDraftsFetched2.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertGreaterThan(draftsFolder.messages.count, numDrafts)
    }

    func testSyncFlags() {
        let emailsFetched = expectation(description: "emailsFetched")
        persistentSetup.grandOperator.fetchEmailsAndDecryptConnectInfos(
            [persistentSetup.connectionInfo], folderName: nil, completionBlock: { error in
                XCTAssertNil(error)
                emailsFetched.fulfill()
        })
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        guard let inbox = persistentSetup.model.folderByType(
            .inbox, email: persistentSetup.accountEmail) else {
                XCTAssertTrue(false)
                return
        }

        XCTAssertGreaterThan(inbox.messages.count, 0)

        var expectations = [XCTestExpectation]()
        var counter = 0
        for elm in inbox.messages {
            guard let m = elm as? Message else {
                XCTAssertTrue(false)
                break
            }
            m.flagFlagged = NSNumber.init(value: !m.flagFlagged.boolValue as Bool)
            m.updateFlags()

            let exp = expectation(description: "flagsSynced\(counter)")
            expectations.append(exp)
            counter += 1
            persistentSetup.grandOperator.syncFlagsToServerForFolder(
                m.folder, completionBlock: { error in
                    XCTAssertNil(error)
                    exp.fulfill()
            })
        }
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })
    }

    func testDeleteFolder() {
        testFetchFolders()

        let expFolderCreated = expectation(description: "expFolderCreated")
        persistentSetup.grandOperator.createFolderOfType(
        persistentSetup.account, folderType: .drafts) { error in
            XCTAssertNil(error)
            expFolderCreated.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        guard let draftsFolder = persistentSetup.model.folderByType(
            .drafts, email: persistentSetup.accountEmail) else {
                XCTAssertTrue(false)
                return
        }

        let expFolderDeleted = expectation(description: "expFolderDeleted")
        persistentSetup.grandOperator.deleteFolder( draftsFolder) { error in
            XCTAssertNil(error)
            expFolderDeleted.fulfill()
        }
        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
        })

        XCTAssertNil(persistentSetup.model.folderByType(.drafts,
            email: persistentSetup.accountEmail))

        testFetchFolders()

        XCTAssertNil(persistentSetup.model.folderByType(.drafts,
            email: persistentSetup.accountEmail))
    }
}
