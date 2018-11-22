//
//  FetchNumberOfNewMailsServiceTest.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 16.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import XCTest

import CoreData

@testable import pEpForiOS
@testable import MessageModel

class FetchNumberOfNewMailsServiceTest: CoreDataDrivenTestBase {
    func testBaseCase() {
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()

        let queue = OperationQueue()

        loginIMAP(imapSyncData: imapSyncData, errorContainer: errorContainer, queue: queue)

        let expFoldersFetched = expectation(description: "expFoldersFetched")
        guard let syncFoldersOp = SyncFoldersFromServerOperation(parentName: #function,
                                                                 imapSyncData: imapSyncData)
            else {
                XCTFail()
                return
        }
        syncFoldersOp.completionBlock = {
            syncFoldersOp.completionBlock = nil
            expFoldersFetched.fulfill()
        }

        queue.addOperation(syncFoldersOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(syncFoldersOp.hasErrors())
        })

        let expNumMails = expectation(description: "expNumMails")
        var numMails: Int?
        let fetchNumMailsOp = FetchNumberOfNewMailsService(
            imapConnectionDataCache: nil, errorContainer: errorContainer)
        fetchNumMailsOp.start() { theNumMails in
            numMails = theNumMails
            expNumMails.fulfill()
        }

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertNotNil(numMails)
            XCTAssertNil(errorContainer.error)
        })
    }
}
