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

//    override func setUp() {
//        super.setUp()
//        let yahooAccount = TestData().createWorkingCdAccountYahoo()
//        yahooAccount.identity?.isMySelf = true
//        TestUtil.skipValidation()
//        Record.saveAndWait()
//        cdAccount = yahooAccount
//
//        imapConnectInfo = cdAccount.imapConnectInfo
//        smtpConnectInfo = cdAccount.smtpConnectInfo
//        imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
//
//        XCTAssertNotNil(imapConnectInfo)
//        XCTAssertNotNil(smtpConnectInfo)
//    }
//    
//    func test_UNDERSTAND() {
//        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
//        let errorContainer = ErrorContainer()
//
//        let imapLogin = LoginImapOperation(
//            errorContainer: errorContainer, imapSyncData: imapSyncData)
//        imapLogin.completionBlock = {
//            imapLogin.completionBlock = nil
//            XCTAssertNotNil(imapSyncData.sync)
//        }
//
//        let expFoldersFetched = expectation(description: "expFoldersFetched")
//        let fetchFoldersOp = FetchFoldersOperation(imapSyncData: imapSyncData)
//        fetchFoldersOp.addDependency(imapLogin)
//        fetchFoldersOp.completionBlock = {
//            fetchFoldersOp.completionBlock = nil
//            expFoldersFetched.fulfill()
//        }
//
//        let queue = OperationQueue()
//        queue.addOperation(imapLogin)
//        queue.addOperation(fetchFoldersOp)
//
//        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
//            XCTAssertNil(error)
//            XCTAssertFalse(imapLogin.hasErrors())
//            XCTAssertFalse(fetchFoldersOp.hasErrors())
//        })
//    }
}
