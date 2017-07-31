//
//  SpecialUseMailboxesTest.swift
//  pEpForiOS
//
//  Created by buff on 26.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

import CoreData
import pEpForiOS
import MessageModel

class SpecialUseMailboxesTest: OperationTestBase {

    func test_UNDERSTAND() {
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()

        let imapLogin = LoginImapOperation(
            errorContainer: errorContainer, imapSyncData: imapSyncData)
        imapLogin.completionBlock = {
            imapLogin.completionBlock = nil
            XCTAssertNotNil(imapSyncData.sync)
        }

        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let fetchFoldersOp = FetchFoldersOperation(imapSyncData: imapSyncData)
        fetchFoldersOp.addDependency(imapLogin)
        fetchFoldersOp.completionBlock = {
            fetchFoldersOp.completionBlock = nil
            expFoldersFetched.fulfill()
        }

        let expFoldersCreated = expectation(description: "expFoldersCreated")
        let createRequiredFoldersOp = CreateLocalRequiredFoldersOperation(account: cdAccount)
        createRequiredFoldersOp.addDependency(fetchFoldersOp)
        createRequiredFoldersOp.completionBlock = {
            expFoldersCreated.fulfill()
        }

        let queue = OperationQueue()
        queue.addOperation(imapLogin)
        queue.addOperation(fetchFoldersOp)
        queue.addOperation(createRequiredFoldersOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors())
            XCTAssertFalse(fetchFoldersOp.hasErrors())
            XCTAssertFalse(createRequiredFoldersOp.hasErrors())

//            let folderDrafts = CdFolder.by(folderType: .drafts, account: cdAccount)
//            XCTAssertNotNil(folderDrafts)
//
//            let folderDrafts = CdFolder.by(folderType: .inbox, account: cdAccount)
//            XCTAssertNotNil(folderDrafts)

        })
    }
}
