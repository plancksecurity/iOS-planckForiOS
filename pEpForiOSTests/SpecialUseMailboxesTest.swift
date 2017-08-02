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

    /// This test makes sense only for a Yahoo account as special-use
    /// mailbox names and purposes will differ using other providers. 
    /// Or Special-Use Mailboxes are not even supported by the server.
    func testSpecialMailboxesAndRequiredFolders() {
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()

        let imapLogin = LoginImapOperation(parentName: #function, errorContainer: errorContainer, imapSyncData: imapSyncData)
        imapLogin.completionBlock = {
            imapLogin.completionBlock = nil
            XCTAssertNotNil(imapSyncData.sync)
        }

        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let fetchFoldersOp = FetchFoldersOperation(parentName: #function, imapSyncData: imapSyncData)
        fetchFoldersOp.addDependency(imapLogin)
        fetchFoldersOp.completionBlock = {
            fetchFoldersOp.completionBlock = nil
            let allFolders = CdFolder.all() as! [CdFolder]
            // triggers only for Yahoo accounts
            self.assertYahooFolderTypes(for: allFolders)

            expFoldersFetched.fulfill()
        }

        let expFoldersCreated = expectation(description: "expFoldersCreated")
        let createRequiredFoldersOp = CreateRequiredFoldersOperation(parentName: #function, imapSyncData: imapSyncData)
        //CreateRequiredFoldersOperation(imapSyncData: imapSyncData)
        createRequiredFoldersOp.addDependency(fetchFoldersOp)
        createRequiredFoldersOp.completionBlock = {
            let allFolders = CdFolder.all() as! [CdFolder]
            // triggers only for Yahoo accounts
            self.assert(yahooFolders: allFolders)

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

            let allFolders = CdFolder.all() as! [CdFolder]
            // triggers only for Yahoo accounts
            self.assert(yahooFolders: allFolders)
        })
    }

    //MARK: - HELPER

    //MARK: Only for Yahoo Accoounts


    /// Runs all Yahoo specific assertions on:
    ///
    /// - Parameter folders: folders fetched from a Yahoo account and created in pEp DB
    func assert(yahooFolders folders: [CdFolder]) {
        assertYahooFolderTypes(for: folders)
        assertOnlyRequiredFoldersCreated(for: folders)
    }

    private let yahooFolderInfo = ["Bulk Mail":FolderType.spam,
                                   "Archive":.archive,
                                   "Draft":.drafts,
                                   "Inbox":.inbox,
                                   "Sent":.sent,
                                   "Trash":.trash]

    /// Asserts all Yahoo folders have been created.
    ///
    /// - Parameter yahooFolders: folders fetched from a Yahoo account and created in pEp DB
    private func assertAllYahooFolderNamesExist(in yahooFolders:[CdFolder]) {
        guard let account = yahooFolders.first?.account,
            isYahooAccount(account:account)
            else {
                return
        }
        let folderNames: [String] = yahooFolders.map { $0.name! }
        let yahooFolderNames = yahooFolderInfo.map { $0.0 }
        for yahooName in yahooFolderNames {
            XCTAssertTrue(folderNames.contains(yahooName))
        }
    }

    ///
    /// Assures all folders fetched from Yahoo exist and are saved with the correct folder type.
    ///
    /// - Parameter yahooFolders: folders fetched from a Yahoo account and created in pEp DB
    private func assertYahooFolderTypes(for yahooFolders:[CdFolder]) {
        guard let account = yahooFolders.first?.account,
            isYahooAccount(account:account)
            else {
                return
        }
        assertAllYahooFolderNamesExist(in: yahooFolders)
        for folder in yahooFolders {
            if folder.name! == "Bulk Mail" {
                XCTAssertTrue(FolderType.fromInt(folder.folderType) == .spam)
            } else if folder.name! == "Archive" {
                XCTAssertTrue(FolderType.fromInt(folder.folderType) == .archive)
            } else if folder.name! == "Draft" {
                XCTAssertTrue(FolderType.fromInt(folder.folderType) == .drafts)
            } else if folder.name! == "Inbox" {
                XCTAssertTrue(FolderType.fromInt(folder.folderType) == .inbox)
            } else if folder.name! == "Sent" {
                XCTAssertTrue(FolderType.fromInt(folder.folderType) == .sent)
            } else if folder.name! == "Trash" {
                XCTAssertTrue(FolderType.fromInt(folder.folderType) == .trash)
            }
        }
    }

    /// Some folders should not be created. Yahoo has a folder "Draft" with special
    /// use purpose \Drafts, so the pEp required folder "Drafts" (leading "s") should not be created.
    /// Folders are:
    ///  pep:    Drafts, Spam
    /// yahooo:  Draft,  Bulkmail
    ///
    /// - Parameter yahooFolders: folders fetched from a Yahoo account and created in pEp DB
    private func assertOnlyRequiredFoldersCreated(for yahooFolders:[CdFolder]) {
        // return if we are not dealing with a Yahoo account
        guard let account = yahooFolders.first?.account,
            isYahooAccount(account:account)
            else {
                return
        }
        for folder in yahooFolders {
            let pEpNamesThatDifferFromYahooNames = ["Drafts", "Spam"]
            let nonRequiredFoldersHaveBeenCreated = pEpNamesThatDifferFromYahooNames.contains(folder.name!)
            XCTAssertFalse(nonRequiredFoldersHaveBeenCreated)
        }
    }

    private func isYahooAccount(account: CdAccount) -> Bool {
        if (account.identity?.address?.contains("yahoo"))! {
            return true
        }
        return false
    }
}
