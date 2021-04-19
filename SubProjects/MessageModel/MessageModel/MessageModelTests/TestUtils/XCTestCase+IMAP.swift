//
//  XCTestCase+IMAP.swift
//  MessageModelTests
//
//  Created by Dirk Zimmermann on 11.06.20.
//  Copyright © 2020 pEp Security S.A. All rights reserved.
//

import Foundation
import XCTest
import CoreData

@testable import MessageModel

extension XCTestCase {
    public func loginIMAP(imapConnection: ImapConnectionProtocol,
                          errorContainer: ErrorContainerProtocol,
                          queue: OperationQueue,
                          context: NSManagedObjectContext? = nil) {
        let expImapLoggedIn = expectation(description: "expImapLoggedIn")

        let imapLogin = LoginImapOperation(parentName: #function,
                                           context: context,
                                           errorContainer: errorContainer,
                                           imapConnection: imapConnection)
        imapLogin.completionBlock = {
            imapLogin.completionBlock = nil
            expImapLoggedIn.fulfill()
        }
        queue.addOperation(imapLogin)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors)
        })
    }

    public func fetchFoldersIMAP(imapConnection: ImapConnectionProtocol,
                                 queue: OperationQueue) {
        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let syncFoldersOp = SyncFoldersFromServerOperation(parentName: #function,
                                                           imapConnection: imapConnection)
        syncFoldersOp.completionBlock = {
            syncFoldersOp.completionBlock = nil
            expFoldersFetched.fulfill()
        }

        queue.addOperation(syncFoldersOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(syncFoldersOp.hasErrors)
        })
    }

    func appendMailsIMAP(folder: CdFolder,
                         imapConnection: ImapConnectionProtocol,
                         errorContainer: ErrorContainerProtocol,
                         queue: OperationQueue) {
        let expSentAppended = expectation(description: "expSentAppended")
        let appendOp = AppendMailsToFolderOperation(parentName: #function,
                                                    folder: folder,
                                                    errorContainer: errorContainer,
                                                    imapConnection: imapConnection)
        appendOp.completionBlock = {
            appendOp.completionBlock = nil
            expSentAppended.fulfill()
        }

        queue.addOperation(appendOp)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(appendOp.hasErrors)
        })
    }

    public func fetchNumberOfNewMails(errorContainer: ErrorContainerProtocol,
                                      context: NSManagedObjectContext) -> Int? {
        let expNumMails = expectation(description: "expNumMails")
        var numMails: Int?
        let fetchNumMailsOp = FetchNumberOfNewMailsService(imapConnectionDataCache: nil,
                                                           context: context)
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
