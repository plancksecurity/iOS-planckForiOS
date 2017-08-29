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

    func syncOnceAndWait(testCase: XCTestCase) {
//                       let modelDelegate = MessageModelObserver()
//            MessageModelConfig.messageFolderDelegate = modelDelegate
//
//            let sendLayerDelegate = SendLayerObserver()

            let networkService = NetworkService(parentName: "//BUFF: TEST \(#function)")
            networkService.sleepTimeInSeconds = 2

            // A temp variable is necassary, since the networkServiceDelegate is weak
            let expAccountsSynced = testCase.expectation(description: "expSingleAccountSynced1")
            var del = NetworkServiceObserver(
                expAccountsSynced: expAccountsSynced,
                failOnError: useCorrectSmtpAccount)

            networkService.networkServiceDelegate = del
            networkService.sendLayerDelegate = sendLayerDelegate

            let cdAccount = useCorrectSmtpAccount ? TestData().createWorkingCdAccount() :
                TestData().createSmtpTimeOutCdAccount()
            TestUtil.skipValidation()
            Record.saveAndWait()

            networkService.start()

            // Wait for first sync, mainly to have folders
            waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
                XCTAssertNil(error)
            })
    }
    func createRequiredFoldersAndWait(testCase: XCTestCase) {
        guard let imapConnectInfo = self.imapConnectInfo else {
            XCTFail("No imapConnectInfo")
            return
        }
        let imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)
        XCTAssertNotNil(imapConnectInfo)


        let imapLogin = LoginImapOperation(
            parentName: #function, imapSyncData: imapSyncData)

        let expFoldersFetched = testCase.expectation(description: "expFoldersFetched")
        let fetchFoldersOp = FetchFoldersOperation(
            parentName: #function, imapSyncData: imapSyncData)
        fetchFoldersOp.addDependency(imapLogin)
        fetchFoldersOp.completionBlock = {
            fetchFoldersOp.completionBlock = nil
            expFoldersFetched.fulfill()
        }

        let backgroundQueue = OperationQueue()
        backgroundQueue.addOperation(imapLogin)
        backgroundQueue.addOperation(fetchFoldersOp)

        testCase.waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors())
            XCTAssertFalse(fetchFoldersOp.hasErrors())
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
            //            finished = true
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
