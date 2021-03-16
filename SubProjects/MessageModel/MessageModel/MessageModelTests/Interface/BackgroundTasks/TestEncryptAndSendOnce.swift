//
//  TestEncryptAndSendOnce.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 16.03.21.
//  Copyright © 2021 pEp Security S.A. All rights reserved.
//

import XCTest

@testable import MessageModel

class TestEncryptAndSendOnce: PersistentStoreDrivenTestBase {
    func testNothingToSend() throws {
        let sender: EncryptAndSendOnceProtocol = EncryptAndSendOnce()

        let expHaveRun = expectation(description: "expHaveRun")

        sender.sendAllOutstandingMessages() { error in
            XCTAssertNil(error)
            expHaveRun.fulfill()
        }

        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testNothingToSendAndCancel() throws {
        let sender: EncryptAndSendOnceProtocol = EncryptAndSendOnce()

        let expHaveRun = expectation(description: "expHaveRun")

        sender.sendAllOutstandingMessages() { error in
            XCTAssertNil(error)
            expHaveRun.fulfill()
        }

        sender.cancel()

        waitForExpectations(timeout: TestUtil.waitTime)
    }

    func testSendMails() throws {
        TestUtil.syncAndWait(testCase: self)

        guard let myself = cdAccount.identity else {
            XCTFail()
            return
        }

        guard let outFolder = outgoingFolder() else {
            XCTFail()
            return
        }

        let cdMsg = outgoingMessage(from: myself, to: myself, folder: outFolder)
        moc.saveAndLogErrors()
    }

    // MARK: -- Helpers

    func outgoingFolder() -> CdFolder? {
        guard var cdFolders = cdAccount.folders?.array as? [CdFolder] else {
            return nil
        }
        cdFolders = cdFolders.filter { $0.folderType == FolderType.outbox }

        return cdFolders.first
    }

    func outgoingMessage(from: CdIdentity, to: CdIdentity, folder: CdFolder) -> CdMessage {
        let stringData = "test"

        let cdMsg = CdMessage(context: moc)

        cdMsg.uuid = UUID().uuidString + " " + stringData
        cdMsg.shortMessage = stringData
        cdMsg.longMessage = stringData
        cdMsg.longMessageFormatted = stringData
        cdMsg.sent = Date()
        cdMsg.from = from
        cdMsg.addToTo(to)
        cdMsg.parent = folder

        return cdMsg
    }
}
