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
    
    /*
     *IOS-606 Login fails using Yahoo account*
     To assert the mentioned bug is fixed:
     - the first account in testData.swift has to be an Yahoo account
     - OAuth has to be deactivated for the Yahoo account (enable the "allow less secure clients" option in your Yahoo account)
     */
    func testLoginWorkingAccount() {
        let errorContainer = ErrorContainer()
        let expLoginSucceeds = expectation(description: "LoginSucceeds")

        let imapLogin = LoginImapOperation(
            errorContainer: errorContainer, imapSyncData: imapSyncData)
        imapLogin.completionBlock = {
            imapLogin.completionBlock = nil
            XCTAssertNotNil(self.imapSyncData.sync)
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
