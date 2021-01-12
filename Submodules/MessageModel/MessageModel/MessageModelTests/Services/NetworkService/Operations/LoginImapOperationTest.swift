//
//  LoginImapOperationTest.swift
//  pEpForiOS
//
//  Created by buff on 26.07.17.
//  Copyright © 2017 p≡p Security S.A. All rights reserved.
//

import XCTest

import CoreData
@testable import MessageModel

class LoginImapOperationTest: PersistentStoreDrivenTestBase {

    /*
     *IOS-606 Login fails using Yahoo account*
     To assert the mentioned bug is fixed:
     - the first account in testData.swift has to be an Yahoo account
     - OAuth has to be deactivated for the Yahoo account (enable the "allow less secure clients" option in your Yahoo account)
     */
    func testLoginWorkingAccount() {
        let errorContainer = ErrorPropagator()
        let expLoginSucceeds = expectation(description: "LoginSucceeds")

        let imapLogin = LoginImapOperation(parentName: #function,
                                           errorContainer: errorContainer,
                                           imapConnection: imapConnection)
        imapLogin.completionBlock = {
            expLoginSucceeds.fulfill()
        }

        let queue = OperationQueue()
        queue.addOperation(imapLogin)

        waitForExpectations(timeout: TestUtil.waitTime) { error in
            XCTAssertNil(error)
        }

        XCTAssertFalse(imapLogin.hasErrors)
    }
}
