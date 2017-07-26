//
//  LoginImapOperationTest.swift
//  pEpForiOS
//
//  Created by buff on 26.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

import CoreData
import pEpForiOS
import MessageModel

class LoginImapOperationTest: OperationTestBase {
    
    override func setUp() {
        super.setUp()
        let newCdAccount = TestData().createWorkingCdAccount()
        newCdAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        cdAccount = newCdAccount

        imapConnectInfo = newCdAccount.imapConnectInfo
        smtpConnectInfo = newCdAccount.smtpConnectInfo
        imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)

        XCTAssertNotNil(imapConnectInfo)
        XCTAssertNotNil(smtpConnectInfo)
    }

    //IOS-606 Login fails using Yahoo account
    func testLoginYahoo() {
        let yahooAccount = TestData().createWorkingCdAccountYahoo()
        yahooAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()

        let imapConnectInfoYahoo = yahooAccount.imapConnectInfo!
        let imapSyncDataYahoo = ImapSyncData(connectInfo: imapConnectInfoYahoo)

        let errorContainer = ErrorContainer()
        let expLoginSucceeds = expectation(description: "LoginSucceeds")

        let imapLogin = LoginImapOperation(
            errorContainer: errorContainer, imapSyncData: imapSyncDataYahoo)
        imapLogin.completionBlock = {
            imapLogin.completionBlock = nil
            XCTAssertNotNil(imapSyncDataYahoo.sync)
            expLoginSucceeds.fulfill()
        }

        let queue = OperationQueue()
        queue.addOperation(imapLogin)

        waitForExpectations(timeout: TestUtil.waitTime, handler: { error in
            XCTAssertNil(error)
            XCTAssertFalse(imapLogin.hasErrors())
        })
    }
    
}
