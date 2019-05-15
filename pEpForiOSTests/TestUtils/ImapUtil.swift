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
    @available(*, deprecated, message: "777")
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

    @available(*, deprecated, message: "777")
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

    @available(*, deprecated, message: "777")
    public func appendMailsIMAP(folder: CdFolder,
                                imapSyncData: ImapSyncData,
                                errorContainer: ServiceErrorProtocol,
                                queue: OperationQueue) {
        let expSentAppended = expectation(description: "expSentAppended")
        let appendOp = AppendMailsOperation(parentName: #function,
                                            folder: folder,
                                            imapSyncData: imapSyncData,
                                            errorContainer: errorContainer)
        appendOp.completionBlock = {
            appendOp.completionBlock = nil
            expSentAppended.fulfill()
        }

        queue.addOperation(appendOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(appendOp.hasErrors())
        })
    }

    @available(*, deprecated, message: "777")
    public func fetchNumberOfNewMails(errorContainer: ServiceErrorProtocol) -> Int? {
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

        return numMails
    }
}
