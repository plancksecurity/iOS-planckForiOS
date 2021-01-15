//
//  CdAccount+TestUtils.swift
//  pEpForiOS
//
//  Created by Andreas Buff on 29.08.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest
@testable import MessageModel
import CoreData
import pEpIOSToolbox

//!!!: move to MM
extension CdAccount {
    /**
     - Note: The test for the `sendFrom` identity is very strict and will fail
     in cases like "two identities that 'only' differ in their username".
     */
    public func allMessages(inFolderOfType type: FolderType,
                            sendFrom from: CdIdentity? = nil) -> [CdMessage] {
        guard let moc = from?.managedObjectContext else {
            Log.shared.errorAndCrash("No MOC")
            return []
        }
        var predicates = [NSPredicate]()
        let pIsInAccount = NSPredicate(format: "parent.%@ = %@",
                                     CdFolder.RelationshipName.account, self)
        predicates.append(pIsInAccount)
        let pIsInFolderOfType = NSPredicate(format: "parent.%@ == %d",
                                CdFolder.AttributeName.folderTypeRawValue, type.rawValue)
        predicates.append(pIsInFolderOfType)
        if let from = from {
            let pSenderIdentity = NSPredicate(format: "%K = %@",
                                              CdMessage.RelationshipName.from, from)
            predicates.append(pSenderIdentity)
        }
        let finalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        guard
            let messages = CdMessage.all(predicate: finalPredicate, in: moc) as? [CdMessage]
            else {
            return []
        }

        return messages
    }
    
    public func createRequiredFoldersAndWait(testCase: XCTestCase) {
        guard let connectInfo = imapConnectInfo else {
            XCTFail("No imapConnectInfo")
            return
        }
        let imapConnection = ImapConnection(connectInfo: connectInfo)
        XCTAssertNotNil(connectInfo)

        let imapLogin = LoginImapOperation(parentName: #function,
                                           imapConnection: imapConnection)

        let expFoldersFetched = testCase.expectation(description: "expFoldersFetched")
        let syncFoldersOp = SyncFoldersFromServerOperation(parentName: #function,
                                                           imapConnection: imapConnection)
        syncFoldersOp.addDependency(imapLogin)
        syncFoldersOp.completionBlock = {
            syncFoldersOp.completionBlock = nil
            expFoldersFetched.fulfill()
        }

        let backgroundQueue = OperationQueue()
        backgroundQueue.addOperation(imapLogin)
        backgroundQueue.addOperation(syncFoldersOp)

        testCase.waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors)
            XCTAssertFalse(syncFoldersOp.hasErrors)
        }

        let expCreated1 = testCase.expectation(description: "expCreated")
        let opCreate1 = CreateRequiredFoldersOperation(parentName: #function,
                                                       imapConnection: imapConnection)
        opCreate1.completionBlock = {
            expCreated1.fulfill()
        }
        backgroundQueue.addOperation(opCreate1)

        testCase.waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(opCreate1.hasErrors)
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
