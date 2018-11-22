//
//  ImapUtil.swift
//  pEpForiOSTests
//
//  Created by Dirk Zimmermann on 20.11.18.
//  Copyright © 2018 p≡p Security S.A. All rights reserved.
//

import Foundation

import XCTest

@testable import pEpForiOS
@testable import MessageModel

extension XCTestCase {
    public func loginIMAP(imapSyncData: ImapSyncData,
                          errorContainer: ServiceErrorProtocol,
                          queue: OperationQueue) {
        let expImapLoggedIn = expectation(description: "expImapLoggedIn")

        let imapLogin = LoginImapOperation(
            parentName: #function,
            errorContainer: errorContainer, imapSyncData: imapSyncData)
        imapLogin.completionBlock = {
            imapLogin.completionBlock = nil
            XCTAssertNotNil(imapSyncData.sync)
            expImapLoggedIn.fulfill()
        }
        queue.addOperation(imapLogin)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors())
        })
    }

    public func fetchFoldersIMAP(imapSyncData: ImapSyncData,
                                 queue: OperationQueue) {
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
    }
}
