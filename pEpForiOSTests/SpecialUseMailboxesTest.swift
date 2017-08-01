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

    //
    func test_UNDERSTAND() {
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        let errorContainer = ErrorContainer()

        let imapLogin = LoginImapOperation(parentName: #function, errorContainer: errorContainer, imapSyncData: imapSyncData)
            //LoginImapOperation(
            //errorContainer: errorContainer, imapSyncData: imapSyncData)
        imapLogin.completionBlock = {
            imapLogin.completionBlock = nil
            XCTAssertNotNil(imapSyncData.sync)
        }

        let expFoldersFetched = expectation(description: "expFoldersFetched")
        let fetchFoldersOp = FetchFoldersOperation(parentName: #function, imapSyncData: imapSyncData)
        fetchFoldersOp.addDependency(imapLogin)
        fetchFoldersOp.completionBlock = {
            fetchFoldersOp.completionBlock = nil
            print("####BUF:\nfetched folders")
            let allFolders = CdFolder.all() as! [CdFolder]
            for folder in allFolders {
                print("name: \(String(describing: folder.name)) -- type:\(String(describing: FolderType.fromInt(folder.folderType)))")
            }

            expFoldersFetched.fulfill()
        }

        let expFoldersCreated = expectation(description: "expFoldersCreated")
        let createRequiredFoldersOp = CreateRequiredFoldersOperation(parentName: #function, imapSyncData: imapSyncData)
            //CreateRequiredFoldersOperation(imapSyncData: imapSyncData)
        createRequiredFoldersOp.addDependency(fetchFoldersOp)
        createRequiredFoldersOp.completionBlock = {
            print("####BUF:\n finished CreateRequiredFoldersOperation")
            let allFolders = CdFolder.all() as! [CdFolder]
            for folder in allFolders {
                print("name: \(String(describing: folder.name)) -- type:\(String(describing: FolderType.fromInt(folder.folderType)))")
            }

            let allFolderNames: [String] = allFolders.map { $0.name! }
            XCTAssertTrue(allFolderNames.contains("Bulk Mail"))
            XCTAssertTrue(allFolderNames.contains("Archive"))
            XCTAssertTrue(allFolderNames.contains("Draft"))
            XCTAssertTrue(allFolderNames.contains("Inbox"))
            XCTAssertTrue(allFolderNames.contains("Sent"))

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

//            for folder in allFolders {
//                print("name: \(String(describing: folder.name)) -- type:\(String(describing: FolderType.fromInt(folder.folderType)))")
//            }

            for folder in allFolders {
//                print("name: \(String(describing: folder.name)) -- type:\(String(describing: FolderType.fromInt(folder.folderType)))")
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

                // Some folders should not be created. Yahoo has a folder "Draft" with special 
                // use purpose \Drafts, so the pEp required folder "Drafts" should not be created.
                let pEpYahooNameDiff = ["Drafts", "Spam"]
                let nonRequiredFoldersHaveBeenCreated = pEpYahooNameDiff.contains(folder.name!)
                XCTAssertFalse(nonRequiredFoldersHaveBeenCreated)
            }
        })
    }
}
