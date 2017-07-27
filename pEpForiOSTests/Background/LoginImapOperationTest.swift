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
        let cdAccount = TestData().createWorkingCdAccount()
        cdAccount.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()
        self.cdAccount = cdAccount

        imapConnectInfo = cdAccount.imapConnectInfo
        smtpConnectInfo = cdAccount.smtpConnectInfo
        imapSyncData = ImapSyncData(connectInfo: imapConnectInfo)

        XCTAssertNotNil(imapConnectInfo)
        XCTAssertNotNil(smtpConnectInfo)
    }

    func testLoginWorkingAccount() {
        //BUFF: change to setup account
        let account = TestData().createWorkingCdAccount()
        account.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()

        let imapConnectInfoYahoo = account.imapConnectInfo!
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

    //IOS-606 Login fails using Yahoo account
    func testLoginWorkingAccountYahoo() {
        let account = TestData().createWorkingCdAccountYahoo()
        account.identity?.isMySelf = true
        TestUtil.skipValidation()
        Record.saveAndWait()

        let imapConnectInfoYahoo = account.imapConnectInfo!
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
