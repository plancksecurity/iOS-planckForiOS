//
//  CdAccount+TestUtils.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 29.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
import MessageModel
import pEpForiOS

extension CdAccount {
    public func allMessages(inFolderOfType type: FolderType,
                            sendFrom from: CdIdentity? = nil) -> [CdMessage] {
        guard let messages = CdMessage.all() as? [CdMessage] else {
            return []
        }

        let msgs1 = messages.filter {
            $0.parent?.account == self && $0.parent?.folderType == type
        }
        if let id = from {
            let msgs2 = msgs1.filter {
                $0.from == id
            }
            return msgs2
        } else {
            return msgs1
        }
    }
    
    public func createRequiredFoldersAndWait() {
        let testCase = XCTestCase()
        guard let imapConnectInfo = self.imapConnectInfo else {
            XCTFail("No imapConnectInfo")
            return
        }
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        XCTAssertNotNil(imapConnectInfo)

        let imapLogin = LoginImapOperation(parentName: #function, imapSyncData: imapSyncData)

        let expFoldersFetched = testCase.expectation(description: "expFoldersFetched")
        let syncFoldersOp = SyncFoldersFromServerOperation(
            parentName: #function, imapSyncData: imapSyncData)
        syncFoldersOp.addDependency(imapLogin)
        syncFoldersOp.completionBlock = {
            syncFoldersOp.completionBlock = nil
            expFoldersFetched.fulfill()
        }

        let backgroundQueue = OperationQueue()
        backgroundQueue.addOperation(imapLogin)
        backgroundQueue.addOperation(syncFoldersOp)

        testCase.waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors())
            XCTAssertFalse(syncFoldersOp.hasErrors())
        })

        let expCreated1 = testCase.expectation(description: "expCreated")
        let opCreate1 = CreateRequiredFoldersOperation(
            parentName: #function, imapSyncData: imapSyncData)
        opCreate1.completionBlock = {
            opCreate1.completionBlock = nil
            expCreated1.fulfill()
        }
        backgroundQueue.addOperation(opCreate1)

        testCase.waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opCreate1.hasErrors())
        })

        for ft in FolderType.requiredTypes {
            if
                let cdF = CdFolder.by(folderType: ft, account: self),
                let folderName = cdF.name {
                if let sep = cdF.folderSeparatorAsString(), cdF.parent != nil {
                    XCTAssertTrue(folderName.contains(sep))
                }
            } else {
                XCTFail("expecting folder of type \(ft) with defined name")
            }
        }
    }
}
